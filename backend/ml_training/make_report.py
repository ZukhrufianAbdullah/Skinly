"""
Skinly - Membuat laporan evaluasi model (model card) dalam format Markdown.

Membaca artefak hasil training (`training_summary_*.json`) dari satu atau dua
folder model, lalu menulis laporan perbandingan + model card ke file Markdown.

Pemakaian (dari folder backend):
    python ml_training/make_report.py
    python ml_training/make_report.py --model-dir app/ml --compare-dir app/ml_effnetb0
    python ml_training/make_report.py --out ../docs/MODEL_REPORT.md
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

TARGETS = {
    "test_macro_f1": (0.60, ">=", "Macro-F1 test"),
    "dry_recall": (0.45, ">=", "Recall kelas dry"),
    "ece_after": (0.10, "<", "ECE setelah kalibrasi"),
}

BACKBONE_LABEL = {
    "mobilenetv2": "MobileNetV2",
    "efficientnetb0": "EfficientNetB0",
}


def load_summary(model_dir: Path) -> tuple[Path, dict[str, Any]]:
    candidates = sorted(model_dir.glob("training_summary_*.json"))
    if not candidates:
        raise SystemExit(f"Tidak ada training_summary_*.json di {model_dir}")
    path = candidates[-1]
    return path, json.loads(path.read_text(encoding="utf-8"))


def fmt(value: float | None, digits: int = 4) -> str:
    if value is None:
        return "-"
    return f"{value:.{digits}f}"


def pct(value: float | None, digits: int = 1) -> str:
    if value is None:
        return "-"
    return f"{value * 100:.{digits}f}%"


def status_icon(ok: bool) -> str:
    return "PASS" if ok else "FAIL"


def target_rows(summary: dict[str, Any]) -> list[str]:
    ece_after = summary.get("calibration", {}).get("ece_after")
    values = {
        "test_macro_f1": summary.get("test_macro_f1"),
        "dry_recall": summary.get("per_class", {}).get("dry", {}).get("recall"),
        "ece_after": ece_after,
    }
    rows = ["| Target | Ambang | Hasil | Status |", "| --- | --- | --- | --- |"]
    for key, (threshold, op, label) in TARGETS.items():
        value = values[key]
        if value is None:
            rows.append(f"| {label} | {op} {threshold:g} | - | SKIP |")
            continue
        ok = value >= threshold if op == ">=" else value < threshold
        rows.append(f"| {label} | {op} {threshold:g} | {fmt(value)} | {status_icon(ok)} |")
    return rows


def confusion_rows(summary: dict[str, Any]) -> list[str]:
    classes = summary.get("classes", [])
    matrix = summary.get("confusion_matrix", [])
    if not matrix:
        return ["_(tidak tersedia)_"]
    header = "| Aktual \\ Prediksi | " + " | ".join(classes) + " |"
    divider = "| --- |" + " --- |" * len(classes)
    rows = [header, divider]
    for i, class_name in enumerate(classes):
        cells = " | ".join(str(v) for v in matrix[i])
        rows.append(f"| **{class_name}** | {cells} |")
    return rows


def per_class_rows(summary: dict[str, Any]) -> list[str]:
    rows = [
        "| Kelas | Precision | Recall | F1 | Support |",
        "| --- | --- | --- | --- | --- |",
    ]
    for name, metrics in summary.get("per_class", {}).items():
        rows.append(
            f"| {name} | {fmt(metrics.get('precision'))} | {fmt(metrics.get('recall'))} "
            f"| {fmt(metrics.get('f1'))} | {metrics.get('support', '-')} |"
        )
    return rows


def trigger_rows(summary: dict[str, Any]) -> list[str]:
    rates = summary.get("combination_trigger_rate", {})
    if not rates:
        return ["_(tidak tersedia)_"]
    rows = ["| Threshold skor kombinasi | Persentase test set |", "| --- | --- |"]
    for threshold, rate in rates.items():
        marker = " **(default)**" if abs(float(threshold) - 0.50) < 1e-9 else ""
        rows.append(f"| {threshold}{marker} | {pct(rate)} |")
    return rows


def class_count_rows(summary: dict[str, Any]) -> list[str]:
    counts = summary.get("class_counts", {})
    classes = summary.get("classes", [])
    if not counts:
        return ["_(tidak tersedia)_"]
    header = "| Split | " + " | ".join(classes) + " | Total |"
    divider = "| --- |" + " --- |" * len(classes) + " --- |"
    rows = [header, divider]
    for split in ("train", "val", "test"):
        split_counts = counts.get(split, {})
        values = [split_counts.get(c, 0) for c in classes]
        rows.append(f"| {split} | " + " | ".join(str(v) for v in values) + f" | {sum(values)} |")
    return rows


def model_section(summary: dict[str, Any], summary_path: Path, title: str) -> list[str]:
    backbone = summary.get("backbone", "-")
    calibration = summary.get("calibration", {})
    lines = [
        f"## {title}",
        "",
        f"- **Backbone**: {BACKBONE_LABEL.get(backbone, backbone)} (`{backbone}`)",
        f"- **Kelas**: {', '.join(summary.get('classes', []))}",
        f"- **Ukuran input**: {' × '.join(str(v) for v in summary.get('img_size', []))} piksel",
        f"- **Aturan keputusan**: `{summary.get('decision_rule', summary.get('combination_rule', '-'))}` "
        f"({summary.get('rule_version', '-')})",
        f"- **Artefak**: `{summary_path.as_posix()}`",
        "",
        "### Metrik test",
        "",
        "| Metrik | Nilai |",
        "| --- | --- |",
        f"| Accuracy | {fmt(summary.get('test_accuracy'))} |",
        f"| Macro-F1 | {fmt(summary.get('test_macro_f1'))} |",
        f"| Loss | {fmt(summary.get('test_loss'))} |",
        f"| Macro-F1 val terbaik | {fmt(summary.get('best_val_macro_f1'))} |",
        "",
    ]
    if calibration:
        lines += [
            "### Kalibrasi",
            "",
            "| Metrik | Nilai |",
            "| --- | --- |",
            f"| Metode | {calibration.get('method', '-')} |",
            f"| Temperature | {fmt(calibration.get('temperature'), 2)} |",
            f"| ECE sebelum | {fmt(calibration.get('ece_before'))} |",
            f"| ECE sesudah | {fmt(calibration.get('ece_after'))} |",
            "",
        ]
    lines += ["### Metrik per kelas", ""] + per_class_rows(summary) + [""]
    lines += ["### Confusion matrix", ""] + confusion_rows(summary) + [""]
    if "combination_trigger_rate" in summary:
        lines += ["### Trigger kombinasi (rule-v2)", ""] + trigger_rows(summary) + [""]
    lines += ["### Komposisi dataset", ""] + class_count_rows(summary) + [""]
    lines += ["### Status target", ""] + target_rows(summary) + [""]
    return lines


def comparison_section(
    summaries: list[tuple[str, dict[str, Any]]],
) -> list[str]:
    if len(summaries) < 2:
        return []
    lines = [
        "## Perbandingan model",
        "",
        "| Metrik | " + " | ".join(name for name, _ in summaries) + " |",
        "| --- |" + " --- |" * len(summaries),
    ]

    def row(label: str, getter) -> str:
        values = []
        for _, summary in summaries:
            values.append(getter(summary))
        return f"| {label} | " + " | ".join(values) + " |"

    lines.append(row("Test accuracy", lambda s: fmt(s.get("test_accuracy"))))
    lines.append(row("Test macro-F1", lambda s: fmt(s.get("test_macro_f1"))))
    lines.append(
        row(
            "Recall dry",
            lambda s: fmt(s.get("per_class", {}).get("dry", {}).get("recall")),
        )
    )
    lines.append(
        row(
            "Recall oily",
            lambda s: fmt(s.get("per_class", {}).get("oily", {}).get("recall")),
        )
    )
    lines.append(
        row(
            "ECE sesudah kalibrasi",
            lambda s: fmt(s.get("calibration", {}).get("ece_after")),
        )
    )
    if any("combination_trigger_rate" in s for _, s in summaries):
        lines.append(
            row(
                "Trigger kombinasi @0.50",
                lambda s: pct(s.get("combination_trigger_rate", {}).get("0.50")),
            )
        )
    lines.append("")
    best = max(summaries, key=lambda item: item[1].get("test_macro_f1", 0.0))
    lines += [
        f"**Model dengan macro-F1 test tertinggi: {best[0]} "
        f"({fmt(best[1].get('test_macro_f1'))}).**",
        "",
    ]
    return lines


def build_report(
    primary: tuple[str, dict[str, Any], Path],
    secondary: tuple[str, dict[str, Any], Path] | None,
) -> str:
    name, summary, path = primary
    lines = [
        "# Laporan Evaluasi Model Skinly",
        "",
        "Dokumen ini dihasilkan otomatis oleh `ml_training/make_report.py` dari",
        "artefak training. Jangan diedit manual; jalankan ulang skrip setelah training.",
        "",
        "## Ringkasan",
        "",
        f"Model aktif: **{name}** "
        f"({BACKBONE_LABEL.get(summary.get('backbone'), summary.get('backbone'))}), "
        f"dibuat `{summary.get('created_at', '-')}`.",
        "",
        "Model mengklasifikasikan **4 kelas** (`combination`, `dry`, `normal`, `oily`) "
        "secara langsung. Keputusan akhir memakai **rule-v3**: argmax softmax atas",
        "keempat kelas. Model lama 3 kelas masih didukung lewat rule-v2:",
        "",
        "```",
        "combination_score = 2 * min(P(dry), P(oily))",
        "is_combination     = combination_score >= COMBINATION_SCORE_THRESHOLD  # default 0.50",
        "```",
        "",
    ]

    lines += model_section(summary, path, f"Model: {name}")
    if secondary is not None:
        lines += model_section(secondary[1], secondary[2], f"Model pembanding: {secondary[0]}")

    summaries = [(name, summary)]
    if secondary is not None:
        summaries.append((secondary[0], secondary[1]))
    lines += comparison_section(summaries)

    lines += [
        "## Keterbatasan & catatan",
        "",
        "- Dataset test berisi ratusan gambar (lihat komposisi dataset di atas). "
        "Selisih beberapa poin persentase belum tentu signifikan secara statistik.",
        "- Foto berasal dari dataset publik dengan kondisi pencahayaan dan kamera "
        "terbatas; performa pada foto pengguna nyata bisa berbeda.",
        "- Kelas `combination` kini dilatih sebagai kelas terpisah, tetapi batas "
        "visual dengan `dry`/`normal`/`oily` tetap bisa ambigu. Hasil model adalah "
        "**kecenderungan**, bukan diagnosis medis.",
        "- Target awal (macro-F1 ≥ 0.60, recall dry ≥ 0.45) mungkin belum tercapai. "
        "Jika status `FAIL`, lihat tabel status target di atas dan bagian "
        "\"Penyebab & rencana perbaikan\" di bawah.",
        "",
        "## Penyebab target belum tercapai (jika ada)",
        "",
        "1. **Kualitas label dataset**: gambar `dry`/`normal` sering sulit dibedakan "
        "secara visual (sama-sama tidak berminyak), sehingga batas kelas kabur.",
        "2. **Domain foto**: dataset berisi foto close-up wajah dengan variasi "
        "pencahayaan besar; model harus memisahkan tekstur halus.",
        "3. **Ukuran test kecil**: jumlah gambar test terbatas membuat metrik berfluktuasi.",
        "4. **Kemiripan kelas**: `combination` dan `dry`/`normal`/`oily` saling "
        "tumpang tindih secara visual, sehingga butuh data dan augmentasi memadai.",
        "",
        "Rencana perbaikan lanjutan (di luar cakupan iterasi ini):",
        "",
        "- Uji backbone lain (EfficientNetB0/B3) dan bandingkan pada test set yang sama.",
        "- Tambah data `dry`/`normal` yang benar-benar ambigu (mis. kulit kombinasi).",
        "- Terapkan label smoothing atau mixup untuk meredam label noise.",
        "- Kumpulkan test set lokal dari pengguna nyata dengan label dermatologis.",
        "",
        "## Penggunaan yang disarankan",
        "",
        "Skinly adalah alat bantu edukasi perawatan kulit, **bukan** pengganti "
        "diagnosis dokter. Tampilkan selalu probabilitas per kelas dan ingatkan "
        "pengguna bahwa hasil dapat salah. Jangan gunakan untuk keputusan medis.",
        "",
    ]
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Buat laporan evaluasi model Skinly")
    parser.add_argument("--model-dir", default="app/ml", help="Folder model utama")
    parser.add_argument(
        "--compare-dir",
        default=None,
        help="Folder model pembanding (opsional, mis. app/ml_effnetb0)",
    )
    parser.add_argument(
        "--out",
        default="../docs/MODEL_REPORT.md",
        help="File Markdown output (default: ../docs/MODEL_REPORT.md)",
    )
    args = parser.parse_args()

    model_dir = Path(args.model_dir)
    primary_path, primary_summary = load_summary(model_dir)
    secondary = None
    if args.compare_dir:
        compare_dir = Path(args.compare_dir)
        if compare_dir.is_dir():
            secondary_path, secondary_summary = load_summary(compare_dir)
            secondary = (compare_dir.as_posix(), secondary_summary, secondary_path)

    report = build_report((model_dir.as_posix(), primary_summary, primary_path), secondary)
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(report, encoding="utf-8")
    print(f"Laporan ditulis: {out_path.resolve()}")


if __name__ == "__main__":
    main()
