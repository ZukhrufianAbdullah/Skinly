"""
Skinly - Skrip Training Model (4 kelas)

Model dilatih langsung untuk 4 kelas:
    combination, dry, normal, oily

Keputusan akhir memakai argmax softmax (rule-v3). Tidak ada lagi penurunan
kelas combination dari P(dry)/P(oily) seperti pada model 3 kelas.

Struktur dataset yang dibutuhkan (lihat ml_training/prepare_dataset.py):
    backend/dataset/
        train/{combination,dry,normal,oily}
        val/{combination,dry,normal,oily}
        test/{combination,dry,normal,oily}

Cara menjalankan (dari folder backend):
    conda activate skinly
    python ml_training/prepare_dataset.py --source "C:/path/dataset1" "C:/path/dataset2" --clean
    python ml_training/train.py --backbone mobilenetv2

Fitur:
  - class weighting untuk menyeimbangkan keempat kelas
  - augmentasi (rotasi, zoom, translasi, brightness, contrast)
  - seleksi model & early stopping memakai macro-F1 (bukan accuracy)
  - kalibrasi temperature scaling -> confidence lebih jujur
  - opsi backbone EfficientNetB0
  - artefak: model_meta.json, calibration.json, laporan evaluasi
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger(__name__)

IMG_SIZE = (224, 224)
DEFAULT_BATCH_SIZE = 32
DEFAULT_EPOCHS_PHASE1 = 10
DEFAULT_EPOCHS_PHASE2 = 10
LEARNING_RATE_PHASE1 = 1e-3
LEARNING_RATE_PHASE2 = 1e-5
DROPOUT_RATE = 0.35
L2_STRENGTH = 1e-4
DEFAULT_FINE_TUNE_LAYERS = 30
RULE_VERSION = "rule-v3"
SUPPORTED_CLASSES = {"combination", "dry", "normal", "oily"}
SUPPORTED_BACKBONES = ("mobilenetv2", "efficientnetb0")


def find_split_dir(dataset_dir: Path, split: str) -> Path:
    """Cari folder split, mendukung 'val' maupun 'valid'."""
    candidates = [dataset_dir / split]
    if split == "val":
        candidates.append(dataset_dir / "valid")
    for candidate in candidates:
        if candidate.is_dir():
            return candidate
    raise SystemExit(
        f"Folder split '{split}' tidak ditemukan di {dataset_dir}. "
        "Jalankan ml_training/prepare_dataset.py terlebih dahulu."
    )


def discover_class_names(train_dir: Path) -> list[str]:
    """Ambil nama kelas dari subfolder train, harus huruf kecil."""
    class_names = sorted(
        p.name for p in train_dir.iterdir() if p.is_dir() and not p.name.startswith(".")
    )
    if not class_names:
        raise SystemExit(f"Tidak ada subfolder kelas di {train_dir}.")

    invalid = [name for name in class_names if name != name.lower()]
    if invalid:
        raise SystemExit(
            "Nama folder kelas harus huruf kecil. Ditemukan: "
            f"{invalid}. Jalankan ml_training/prepare_dataset.py --clean."
        )

    unsupported = [name for name in class_names if name not in SUPPORTED_CLASSES]
    if unsupported:
        raise SystemExit(
            f"Kelas tidak didukung: {unsupported}. "
            f"Kelas yang didukung: {sorted(SUPPORTED_CLASSES)}."
        )
    return class_names


def count_images(class_dir: Path) -> int:
    return sum(
        1
        for f in class_dir.iterdir()
        if f.is_file() and f.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}
    )


def check_dataset(dataset_dir: Path, class_names: list[str]) -> dict[str, dict[str, int]]:
    """Pastikan semua split memiliki kelas yang sama dan tidak kosong."""
    counts: dict[str, dict[str, int]] = {}
    for split in ("train", "val", "test"):
        split_dir = find_split_dir(dataset_dir, split)
        counts[split] = {}
        for class_name in class_names:
            class_dir = split_dir / class_name
            if not class_dir.is_dir():
                raise SystemExit(f"Folder kelas tidak ditemukan: {class_dir}")
            count = count_images(class_dir)
            if count == 0:
                raise SystemExit(f"Folder kelas kosong: {class_dir}")
            counts[split][class_name] = count
            logger.info("  %-5s/%-7s: %d gambar", split, class_name, count)
    return counts


def compute_class_weights(counts: dict[str, int], class_names: list[str]) -> dict[int, float]:
    """Bobot berbanding terbalik dengan jumlah sampel (imbalance ringan)."""
    total = sum(counts[name] for name in class_names)
    weights = {}
    for index, name in enumerate(class_names):
        weights[index] = total / (len(class_names) * max(counts[name], 1))
    return weights


def preprocess_mode_for(backbone: str) -> str:
    return "efficientnet" if backbone == "efficientnetb0" else "mobilenet_v2"


def build_model(num_classes: int, backbone: str):
    """Bangun model transfer learning + head klasifikasi."""
    import tensorflow as tf

    if backbone == "efficientnetb0":
        base_model = tf.keras.applications.EfficientNetB0(
            input_shape=(*IMG_SIZE, 3),
            include_top=False,
            weights="imagenet",
        )
        model_name = "skinly_efficientnetb0"
    else:
        base_model = tf.keras.applications.MobileNetV2(
            input_shape=(*IMG_SIZE, 3),
            include_top=False,
            weights="imagenet",
        )
        model_name = "skinly_mobilenetv2"

    base_model.trainable = False

    inputs = tf.keras.Input(shape=(*IMG_SIZE, 3))
    x = base_model(inputs, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.Dropout(DROPOUT_RATE)(x)
    x = tf.keras.layers.Dense(
        256,
        activation="relu",
        kernel_regularizer=tf.keras.regularizers.l2(L2_STRENGTH),
    )(x)
    x = tf.keras.layers.Dropout(DROPOUT_RATE)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation="softmax")(x)

    model = tf.keras.Model(inputs, outputs, name=model_name)
    return model, base_model


def build_augmentation():
    """
    Augmentasi diterapkan pada gambar MENTAH (0-255) sebelum preprocessing,
    jadi value_range default sudah tepat untuk semua backbone.
    """
    import tensorflow as tf

    return tf.keras.Sequential(
        [
            tf.keras.layers.RandomFlip("horizontal"),
            tf.keras.layers.RandomRotation(0.10),
            tf.keras.layers.RandomZoom(0.10),
            tf.keras.layers.RandomTranslation(0.08, 0.08),
            tf.keras.layers.RandomBrightness(0.12),
            tf.keras.layers.RandomContrast(0.12),
        ],
        name="data_augmentation",
    )


def load_split(
    split_dir: Path,
    class_names: list[str],
    batch_size: int,
    backbone: str,
    training: bool,
    augmentation=None,
):
    import tensorflow as tf

    if backbone == "efficientnetb0":
        preprocess_input = tf.keras.applications.efficientnet.preprocess_input
    else:
        preprocess_input = tf.keras.applications.mobilenet_v2.preprocess_input

    ds = tf.keras.utils.image_dataset_from_directory(
        str(split_dir),
        image_size=IMG_SIZE,
        batch_size=batch_size,
        label_mode="categorical",
        class_names=class_names,
        shuffle=training,
        seed=42 if training else None,
    )

    def preprocess(image, label):
        image = tf.cast(image, tf.float32)
        if training and augmentation is not None:
            image = augmentation(image, training=True)
        return preprocess_input(image), label

    ds = ds.map(preprocess, num_parallel_calls=tf.data.AUTOTUNE)
    return ds.prefetch(tf.data.AUTOTUNE)


def collect_predictions(model, dataset):
    """Kumpulkan probabilitas & label asli dari sebuah dataset."""
    import numpy as np

    all_probs = []
    all_labels = []
    for images, labels in dataset:
        probs = model.predict(images, verbose=0)
        all_probs.append(np.asarray(probs))
        all_labels.append(np.argmax(labels.numpy(), axis=1))
    return np.concatenate(all_probs), np.concatenate(all_labels)


def macro_f1(y_true, y_pred) -> float:
    from sklearn.metrics import f1_score

    return float(f1_score(y_true, y_pred, average="macro", zero_division=0))


def expected_calibration_error(probs, labels, n_bins: int = 10) -> float:
    """ECE: selisih rata-rata confidence vs akurasi per bin."""
    import numpy as np

    confidences = probs.max(axis=1)
    predictions = probs.argmax(axis=1)
    correct = (predictions == labels).astype(np.float32)
    bins = np.linspace(0.0, 1.0, n_bins + 1)
    ece = 0.0
    for lower, upper in zip(bins[:-1], bins[1:]):
        mask = (confidences > lower) & (confidences <= upper)
        if not mask.any():
            continue
        bin_weight = mask.mean()
        ece += bin_weight * abs(correct[mask].mean() - confidences[mask].mean())
    return float(ece)


def apply_temperature(probs, temperature: float):
    """Temperature scaling pada output softmax: p^(1/T) lalu dinormalisasi."""
    import numpy as np

    temperature = max(float(temperature), 1e-3)
    scaled = np.power(np.clip(probs, 1e-12, 1.0), 1.0 / temperature)
    return scaled / scaled.sum(axis=1, keepdims=True)


def fit_temperature(probs, labels):
    """Cari temperature terbaik (grid search) meminimalkan NLL pada val set."""
    import numpy as np

    best_temperature = 1.0
    best_nll = float("inf")
    for temperature in np.arange(0.5, 5.01, 0.05):
        calibrated = apply_temperature(probs, temperature)
        correct_probs = calibrated[np.arange(len(labels)), labels]
        nll = float(-np.mean(np.log(np.clip(correct_probs, 1e-12, 1.0))))
        if nll < best_nll:
            best_nll = nll
            best_temperature = float(temperature)
    return best_temperature, best_nll


class MacroF1Callback:
    """
    Callback yang menghitung macro-F1 val set tiap epoch, menyimpannya ke logs
    (agar bisa dipakai EarlyStopping) dan menyimpan checkpoint terbaik.
    Dibuat sebagai factory agar TensorFlow hanya diimpor saat training.
    """

    @staticmethod
    def create(val_ds, checkpoint_path: Path):
        import tensorflow as tf

        class _MacroF1(tf.keras.callbacks.Callback):
            def __init__(self):
                super().__init__()
                self.best = -1.0
                self.checkpoint_path = checkpoint_path

            def on_epoch_end(self, epoch, logs=None):
                logs = logs if logs is not None else {}
                probs, labels = collect_predictions(self.model, val_ds)
                score = macro_f1(labels, probs.argmax(axis=1))
                logs["val_macro_f1"] = score
                logger.info("val_macro_f1: %.4f", score)
                if score > self.best:
                    self.best = score
                    self.model.save(str(self.checkpoint_path))
                    logger.info("Checkpoint terbaik disimpan (macro-F1=%.4f)", score)

        return _MacroF1()


def train(args: argparse.Namespace) -> None:
    import numpy as np
    import tensorflow as tf
    from sklearn.metrics import classification_report, confusion_matrix, precision_recall_fscore_support

    dataset_dir = Path(args.dataset_dir).resolve()
    output_dir = Path(args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    logger.info("TensorFlow versi: %s", tf.__version__)
    logger.info("Dataset: %s", dataset_dir)
    logger.info("Output : %s", output_dir)
    logger.info("Backbone: %s", args.backbone)

    train_dir = find_split_dir(dataset_dir, "train")
    val_dir = find_split_dir(dataset_dir, "val")
    test_dir = find_split_dir(dataset_dir, "test")
    class_names = discover_class_names(train_dir)
    logger.info("Kelas (%d): %s", len(class_names), class_names)

    logger.info("Memeriksa struktur dataset...")
    counts = check_dataset(dataset_dir, class_names)

    class_weights = compute_class_weights(counts["train"], class_names)
    logger.info(
        "Class weights: %s",
        {class_names[i]: round(w, 4) for i, w in class_weights.items()},
    )

    augmentation = build_augmentation()
    train_ds = load_split(train_dir, class_names, args.batch_size, args.backbone, True, augmentation)
    val_ds = load_split(val_dir, class_names, args.batch_size, args.backbone, False)
    test_ds = load_split(test_dir, class_names, args.batch_size, args.backbone, False)

    model, base_model = build_model(len(class_names), args.backbone)
    model.summary(print_fn=logger.info)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    best_val_macro_f1 = 0.0

    def make_callbacks(phase: int, patience: int, min_lr: float):
        return [
            MacroF1Callback.create(val_ds, output_dir / f"checkpoint_phase{phase}_{timestamp}.keras"),
            tf.keras.callbacks.EarlyStopping(
                monitor="val_macro_f1",
                mode="max",
                patience=patience,
                min_delta=1e-4,
                restore_best_weights=True,
                verbose=1,
            ),
            tf.keras.callbacks.ReduceLROnPlateau(
                monitor="val_loss",
                factor=0.5,
                patience=2,
                min_lr=min_lr,
                verbose=1,
            ),
        ]

    # ------------------------------------------------------------------
    # FASE 1: latih head dengan base model dibekukan
    # ------------------------------------------------------------------
    if args.epochs_phase1 > 0:
        logger.info("Fase 1: training head (%d epoch)...", args.epochs_phase1)
        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE_PHASE1),
            loss="categorical_crossentropy",
            metrics=["accuracy"],
        )
        history1 = model.fit(
            train_ds,
            validation_data=val_ds,
            epochs=args.epochs_phase1,
            callbacks=make_callbacks(1, patience=3, min_lr=1e-6),
            class_weight=class_weights,
        )
        best_val_macro_f1 = max(best_val_macro_f1, max(history1.history.get("val_macro_f1", [0.0])))
        logger.info("Fase 1 selesai. Macro-F1 val terbaik: %.4f", best_val_macro_f1)

    # ------------------------------------------------------------------
    # FASE 2: fine-tuning sebagian layer terakhir
    # ------------------------------------------------------------------
    if args.epochs_phase2 > 0 and args.fine_tune_layers > 0:
        logger.info(
            "Fase 2: fine-tuning %d layer terakhir (%d epoch)...",
            args.fine_tune_layers,
            args.epochs_phase2,
        )
        base_model.trainable = True
        for layer in base_model.layers[: -args.fine_tune_layers]:
            layer.trainable = False
        # BatchNormalization tetap dibekukan agar fine-tuning stabil.
        for layer in base_model.layers:
            if isinstance(layer, tf.keras.layers.BatchNormalization):
                layer.trainable = False

        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE_PHASE2),
            loss="categorical_crossentropy",
            metrics=["accuracy"],
        )
        history2 = model.fit(
            train_ds,
            validation_data=val_ds,
            epochs=args.epochs_phase2,
            callbacks=make_callbacks(2, patience=3, min_lr=1e-7),
            class_weight=class_weights,
        )
        best_val_macro_f1 = max(best_val_macro_f1, max(history2.history.get("val_macro_f1", [0.0])))
        logger.info("Fase 2 selesai. Macro-F1 val terbaik: %.4f", best_val_macro_f1)

    # ------------------------------------------------------------------
    # Evaluasi test set + macro-F1
    # ------------------------------------------------------------------
    logger.info("Evaluasi pada test set...")
    test_loss, test_accuracy = model.evaluate(test_ds, verbose=1)
    test_probs, y_true = collect_predictions(model, test_ds)
    y_pred = test_probs.argmax(axis=1)
    test_macro_f1 = macro_f1(y_true, y_pred)
    logger.info(
        "Test accuracy: %.4f | Test macro-F1: %.4f | Test loss: %.4f",
        test_accuracy,
        test_macro_f1,
        test_loss,
    )

    report = classification_report(y_true, y_pred, target_names=class_names, zero_division=0)
    matrix = confusion_matrix(y_true, y_pred)
    precision, recall, f1, support = precision_recall_fscore_support(
        y_true, y_pred, labels=list(range(len(class_names))), zero_division=0
    )
    per_class = {
        name: {
            "precision": round(float(precision[i]), 4),
            "recall": round(float(recall[i]), 4),
            "f1": round(float(f1[i]), 4),
            "support": int(support[i]),
        }
        for i, name in enumerate(class_names)
    }

    # ------------------------------------------------------------------
    # Kalibrasi temperature scaling (pakai val set)
    # ------------------------------------------------------------------
    calibration = {"method": "temperature_scaling", "temperature": 1.0}
    if not args.no_calibration:
        logger.info("Kalibrasi temperature scaling pada val set...")
        val_probs, val_labels = collect_predictions(model, val_ds)
        ece_before = expected_calibration_error(val_probs, val_labels)
        temperature, _ = fit_temperature(val_probs, val_labels)
        calibrated_val = apply_temperature(val_probs, temperature)
        ece_after = expected_calibration_error(calibrated_val, val_labels)
        calibration.update(
            {
                "temperature": round(float(temperature), 4),
                "ece_before": round(ece_before, 4),
                "ece_after": round(ece_after, 4),
            }
        )
        logger.info(
            "Temperature: %.2f | ECE sebelum: %.4f -> sesudah: %.4f",
            temperature,
            ece_before,
            ece_after,
        )

    # ------------------------------------------------------------------
    # Simpan artefak
    # ------------------------------------------------------------------
    model_path = output_dir / "skin_model.keras"
    class_names_path = output_dir / "class_names.json"
    meta_path = output_dir / "model_meta.json"
    calibration_path = output_dir / "calibration.json"
    summary_path = output_dir / f"training_summary_{timestamp}.json"
    report_path = output_dir / f"evaluation_report_{timestamp}.txt"

    model.save(str(model_path))
    class_names_path.write_text(json.dumps(class_names, indent=2), encoding="utf-8")
    meta_path.write_text(
        json.dumps(
            {
                "backbone": args.backbone,
                "img_size": list(IMG_SIZE),
                "preprocessing": preprocess_mode_for(args.backbone),
                "classes": class_names,
                "created_at": timestamp,
                "decision_rule": "argmax(softmax)",
                "rule_version": RULE_VERSION,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    calibration_path.write_text(json.dumps(calibration, indent=2), encoding="utf-8")

    report_path.write_text(
        f"Test Accuracy   : {test_accuracy:.4f}\n"
        f"Test Macro-F1   : {test_macro_f1:.4f}\n"
        f"Test Loss       : {test_loss:.4f}\n\n"
        f"Classification Report:\n{report}\n"
        f"Confusion Matrix (label urut: {', '.join(class_names)}):\n{matrix}\n\n"
        f"Calibration:\n  {json.dumps(calibration, indent=2)}\n",
        encoding="utf-8",
    )

    summary_path.write_text(
        json.dumps(
            {
                "created_at": timestamp,
                "backbone": args.backbone,
                "classes": class_names,
                "img_size": list(IMG_SIZE),
                "preprocessing": preprocess_mode_for(args.backbone),
                "decision_rule": "argmax(softmax) atas kelas 4 kelas",
                "rule_version": RULE_VERSION,
                "class_counts": counts,
                "class_weights": {class_names[i]: round(w, 4) for i, w in class_weights.items()},
                "best_val_macro_f1": round(float(best_val_macro_f1), 6),
                "test_accuracy": round(float(test_accuracy), 6),
                "test_macro_f1": round(test_macro_f1, 6),
                "test_loss": round(float(test_loss), 6),
                "per_class": per_class,
                "confusion_matrix": matrix.tolist(),
                "calibration": calibration,
                "epochs_phase1": args.epochs_phase1,
                "epochs_phase2": args.epochs_phase2,
                "fine_tune_layers": args.fine_tune_layers,
                "dropout": DROPOUT_RATE,
                "l2": L2_STRENGTH,
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    logger.info("Model disimpan: %s", model_path)
    logger.info("Metadata disimpan: %s", meta_path)
    logger.info("Kalibrasi disimpan: %s", calibration_path)
    logger.info("Laporan evaluasi disimpan: %s", report_path)
    logger.info("Ringkasan training disimpan: %s", summary_path)
    logger.info("Selesai. Restart backend agar model baru dimuat.")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Training model Skinly (4 kelas)")
    parser.add_argument("--dataset-dir", default="dataset", help="Folder dataset (default: dataset)")
    parser.add_argument("--output-dir", default="app/ml", help="Folder output model (default: app/ml)")
    parser.add_argument("--batch-size", type=int, default=DEFAULT_BATCH_SIZE)
    parser.add_argument("--epochs-phase1", type=int, default=DEFAULT_EPOCHS_PHASE1)
    parser.add_argument("--epochs-phase2", type=int, default=DEFAULT_EPOCHS_PHASE2)
    parser.add_argument("--fine-tune-layers", type=int, default=DEFAULT_FINE_TUNE_LAYERS)
    parser.add_argument(
        "--backbone",
        choices=SUPPORTED_BACKBONES,
        default="mobilenetv2",
        help="Backbone transfer learning (default: mobilenetv2)",
    )
    parser.add_argument(
        "--no-calibration",
        action="store_true",
        help="Lewati kalibrasi temperature scaling",
    )
    return parser.parse_args()


if __name__ == "__main__":
    try:
        train(parse_args())
    except KeyboardInterrupt:
        logger.warning("Training dihentikan oleh pengguna.")
        sys.exit(130)
