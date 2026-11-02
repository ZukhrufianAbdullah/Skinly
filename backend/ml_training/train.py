"""
Skinly - Skrip Training Model MobileNetV2
Transfer Learning untuk klasifikasi jenis kulit wajah:
  4 kelas: combination, dry, normal, oily

Cara menjalankan:
  conda activate skinly
  cd backend
  python ml_training/train.py

Struktur dataset yang dibutuhkan:
  backend/dataset/
    train/
      combination/  <-- foto kulit kombinasi
      dry/          <-- foto kulit kering
      normal/       <-- foto kulit normal
      oily/         <-- foto kulit berminyak
    val/
      combination/
      dry/
      normal/
      oily/
    test/
      combination/
      dry/
      normal/
      oily/
"""

import os
import sys
import json
import logging
import numpy as np
from pathlib import Path
from datetime import datetime

# Set TF logging
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger(__name__)

# ============================================================
# KONFIGURASI TRAINING
# ============================================================
DATASET_DIR = Path("dataset")
OUTPUT_DIR = Path("app/ml")
MODEL_FILENAME = "skin_model.keras"
CLASS_NAMES_FILENAME = "class_names.json"

IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS_PHASE1 = 10     # Frozen base model
EPOCHS_PHASE2 = 10     # Fine-tuning
LEARNING_RATE_PHASE1 = 1e-3
LEARNING_RATE_PHASE2 = 1e-5
DROPOUT_RATE = 0.3
UNFREEZE_LAYERS = 30    # Jumlah layer yang di-unfreeze saat fine-tuning


def check_dataset():
    """Verifikasi struktur dataset tersedia"""
    required_splits = ["train", "val", "test"]
    required_classes = ["combination", "dry", "normal", "oily"]

    missing = []
    for split in required_splits:
        for cls in required_classes:
            path = DATASET_DIR / split / cls
            if not path.exists():
                missing.append(str(path))

    if missing:
        logger.error("❌ Folder dataset tidak lengkap! Yang belum ada:")
        for m in missing:
            logger.error(f"   - {m}")
        logger.error("\nBuat struktur folder tersebut dan isi dengan foto yang sesuai.")
        logger.error("Lihat ml_training/README.md untuk panduan dataset.")
        sys.exit(1)

    # Hitung jumlah gambar
    for split in required_splits:
        total = 0
        for cls in required_classes:
            count = len(list((DATASET_DIR / split / cls).glob("*.[jJ][pP][gG]")) +
                        list((DATASET_DIR / split / cls).glob("*.[pP][nN][gG]")) +
                        list((DATASET_DIR / split / cls).glob("*.[jJ][pP][eE][gG]")))
            total += count
            logger.info(f"  {split}/{cls}: {count} gambar")
        logger.info(f"  Total {split}: {total} gambar")


def build_model(num_classes: int = 4):
    """
    Bangun model MobileNetV2 dengan transfer learning.
    Base model: MobileNetV2 pretrained ImageNet, dibekukan dulu.
    """
    import tensorflow as tf

    # Base model MobileNetV2
    base_model = tf.keras.applications.MobileNetV2(
        input_shape=(*IMG_SIZE, 3),
        include_top=False,
        weights="imagenet",
    )
    base_model.trainable = False  # Bekukan semua layer base

    # Head klasifikasi
    inputs = tf.keras.Input(shape=(*IMG_SIZE, 3))
    x = base_model(inputs, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.Dropout(DROPOUT_RATE)(x)
    x = tf.keras.layers.Dense(256, activation="relu")(x)
    x = tf.keras.layers.Dropout(DROPOUT_RATE)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation="softmax")(x)

    model = tf.keras.Model(inputs, outputs)
    return model, base_model


def get_data_augmentation():
    """Layer augmentasi data untuk training"""
    import tensorflow as tf
    return tf.keras.Sequential([
        tf.keras.layers.RandomFlip("horizontal"),
        tf.keras.layers.RandomRotation(0.1),
        tf.keras.layers.RandomZoom(0.1),
        tf.keras.layers.RandomBrightness(0.2),
        tf.keras.layers.RandomContrast(0.1),
    ], name="data_augmentation")


def main():
    import tensorflow as tf

    logger.info("🚀 Skinly ML Training dimulai")
    logger.info(f"TensorFlow versi: {tf.__version__}")
    logger.info(f"Dataset: {DATASET_DIR.resolve()}")
    logger.info(f"Output: {OUTPUT_DIR.resolve()}")

    # Cek dataset
    logger.info("\n📁 Memeriksa struktur dataset...")
    check_dataset()

    # Nama kelas (urutan alphabetical - konsisten dengan Keras ImageDataGenerator)
    class_names = sorted(["combination", "dry", "normal", "oily"])
    num_classes = len(class_names)
    logger.info(f"\n🏷️  Kelas ({num_classes}): {class_names}")

    # ============================================================
    # FASE 1: LOAD DATA
    # ============================================================
    logger.info("\n📊 Memuat dataset...")

    # Fungsi preprocessing MobileNetV2
    def preprocess(image, label):
        image = tf.cast(image, tf.float32)
        image = tf.keras.applications.mobilenet_v2.preprocess_input(image)
        return image, label

    # Training dataset dengan augmentasi
    train_ds = tf.keras.utils.image_dataset_from_directory(
        str(DATASET_DIR / "train"),
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode="categorical",
        shuffle=True,
        seed=42,
    )
    train_ds = train_ds.map(preprocess).prefetch(tf.data.AUTOTUNE)

    # Validation dataset
    val_ds = tf.keras.utils.image_dataset_from_directory(
        str(DATASET_DIR / "val"),
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode="categorical",
        shuffle=False,
    )
    val_ds = val_ds.map(preprocess).prefetch(tf.data.AUTOTUNE)

    # Test dataset
    test_ds = tf.keras.utils.image_dataset_from_directory(
        str(DATASET_DIR / "test"),
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode="categorical",
        shuffle=False,
    )
    test_ds = test_ds.map(preprocess)

    # ============================================================
    # FASE 2: BANGUN MODEL
    # ============================================================
    logger.info("\n🔧 Membangun model MobileNetV2...")
    model, base_model = build_model(num_classes)

    # Kompilasi fase 1 (base frozen)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE_PHASE1),
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )
    model.summary()

    # ============================================================
    # FASE 3: TRAINING FASE 1 (Top Layer Only)
    # ============================================================
    logger.info(f"\n🏋️  Fase 1: Training head layer ({EPOCHS_PHASE1} epoch)...")

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    checkpoint_path = OUTPUT_DIR / f"checkpoint_phase1_{timestamp}.keras"

    callbacks_phase1 = [
        tf.keras.callbacks.ModelCheckpoint(
            str(checkpoint_path),
            monitor="val_accuracy",
            save_best_only=True,
            verbose=1,
        ),
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy",
            patience=5,
            restore_best_weights=True,
            verbose=1,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=3,
            verbose=1,
        ),
    ]

    history1 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS_PHASE1,
        callbacks=callbacks_phase1,
    )

    val_acc_phase1 = max(history1.history["val_accuracy"])
    logger.info(f"✅ Fase 1 selesai. Val Accuracy terbaik: {val_acc_phase1:.4f}")

    # ============================================================
    # FASE 4: FINE-TUNING (Unfreeze sebagian layer base)
    # ============================================================
    logger.info(f"\n🔓 Fase 2: Fine-tuning (unfreeze {UNFREEZE_LAYERS} layer terakhir)...")
    base_model.trainable = True

    # Bekukan semua kecuali N layer terakhir
    total_layers = len(base_model.layers)
    for layer in base_model.layers[:-UNFREEZE_LAYERS]:
        layer.trainable = False

    logger.info(f"Total layer base: {total_layers}, yang di-unfreeze: {UNFREEZE_LAYERS}")

    # Kompilasi ulang dengan learning rate lebih kecil
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE_PHASE2),
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )

    callbacks_phase2 = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy",
            patience=5,
            restore_best_weights=True,
            verbose=1,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=3,
            verbose=1,
        ),
    ]

    history2 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS_PHASE2,
        callbacks=callbacks_phase2,
    )

    val_acc_phase2 = max(history2.history["val_accuracy"])
    logger.info(f"✅ Fase 2 selesai. Val Accuracy terbaik: {val_acc_phase2:.4f}")

    # ============================================================
    # FASE 5: EVALUASI
    # ============================================================
    logger.info("\n📈 Evaluasi pada test set...")
    test_loss, test_acc = model.evaluate(test_ds, verbose=1)
    logger.info(f"Test Accuracy: {test_acc:.4f} | Test Loss: {test_loss:.4f}")

    # Confusion matrix & classification report
    try:
        from sklearn.metrics import classification_report, confusion_matrix
        import sklearn  # noqa

        y_true, y_pred = [], []
        for images, labels in test_ds:
            preds = model.predict(images, verbose=0)
            y_true.extend(np.argmax(labels.numpy(), axis=1))
            y_pred.extend(np.argmax(preds, axis=1))

        logger.info("\n📊 Classification Report:")
        report = classification_report(y_true, y_pred, target_names=class_names)
        print(report)

        logger.info("📊 Confusion Matrix:")
        cm = confusion_matrix(y_true, y_pred)
        print(cm)

        # Simpan report
        report_path = OUTPUT_DIR / f"evaluation_report_{timestamp}.txt"
        with open(report_path, "w") as f:
            f.write(f"Test Accuracy: {test_acc:.4f}\n")
            f.write(f"Test Loss: {test_loss:.4f}\n\n")
            f.write("Classification Report:\n")
            f.write(report)
            f.write("\nConfusion Matrix:\n")
            f.write(str(cm))
        logger.info(f"✅ Laporan evaluasi disimpan ke: {report_path}")

    except ImportError:
        logger.warning("scikit-learn tidak tersedia, lewati classification report")

    # ============================================================
    # FASE 6: SIMPAN MODEL
    # ============================================================
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    model_path = OUTPUT_DIR / MODEL_FILENAME
    class_names_path = OUTPUT_DIR / CLASS_NAMES_FILENAME

    model.save(str(model_path))
    logger.info(f"✅ Model disimpan ke: {model_path}")

    with open(class_names_path, "w") as f:
        json.dump(class_names, f, indent=2)
    logger.info(f"✅ Class names disimpan ke: {class_names_path}")

    logger.info(f"\n🎉 Training selesai!")
    logger.info(f"   Val Accuracy Fase 1: {val_acc_phase1:.4f}")
    logger.info(f"   Val Accuracy Fase 2: {val_acc_phase2:.4f}")
    logger.info(f"   Test Accuracy: {test_acc:.4f}")
    logger.info(f"\n👉 Jalankan backend dan uji model baru:")
    logger.info(f"   uvicorn app.main:app --reload")


if __name__ == "__main__":
    main()
