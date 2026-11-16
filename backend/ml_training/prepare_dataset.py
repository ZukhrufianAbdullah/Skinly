"""
Skinly - Menyiapkan dataset 4 kelas (combination, dry, normal, oily).

Mendukung dua bentuk folder sumber:

1. Terstruktur per kelas (dataset utama):
       Sumber/
           train/{Combination,Dry,Normal,Oily}
           valid/{Combination,Dry,Normal,Oily}
           test/{Combination,Dry,Normal,Oily}

2. Flat ala Roboflow (label ada di prefix nama file):
       Sumber/
           train/combination_-_xxxx.jpg
           train/dry_-_xxxx.jpg
           valid/...
           test/...

Skrip ini:
  - Menormalkan nama split: train/training, val/valid/validation, test/testing.
  - Menormalkan nama kelas (tidak peka huruf besar/kecil) termasuk alias
    "kombinasi" -> "combination".
  - Melewati file yang namanya mengandung "copy".
  - Menggabungkan BANYAK folder sumber ke satu folder tujuan.
  - Menghapus duplikat berbasis hash MD5 dengan prioritas test > val > train
    (mencegah kebocoran data), lalu menulis leak_report.txt.

Pemakaian (dari folder backend):
    python ml_training/prepare_dataset.py \
        --source "C:/.../Oily-Dry-Normal-Combination-Skin-Types" \
                 "C:/.../Skin Type.v1i.multiclass" \
        --dest dataset --clean
"""

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
from collections import defaultdict
from pathlib import Path

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
CLASS_ALIASES = {
    "combination": "combination",
    "kombinasi": "combination",
    "combo": "combination",
    "combined": "combination",
    "dry": "dry",
    "kering": "dry",
    "normal": "normal",
    "oily": "oily",
    "berminyak": "oily",
}
SPLIT_ALIASES = {
    "train": "train",
    "training": "train",
    "val": "val",
    "valid": "val",
    "validation": "val",
    "test": "test",
    "testing": "test",
}
SPLITS = ("train", "val", "test")
CLASS_NAMES = ("combination", "dry", "normal", "oily")


def normalize_split(name: str) -> str | None:
    return SPLIT_ALIASES.get(name.strip().lower())


def normalize_class(name: str) -> str | None:
    return CLASS_ALIASES.get(name.strip().lower())


def class_from_filename(filename: str) -> str | None:
    """Ambil label dari prefix nama file flat, mis. 'dry_-_abc.jpg' -> 'dry'."""
    token = re.split(r"[^a-z]+", filename.lower(), maxsplit=1)[0]
    return CLASS_ALIASES.get(token)


def is_duplicate(path: Path) -> bool:
    """Lewati file hasil duplikasi seperti '... - Copy.jpg'."""
    return "copy" in path.stem.lower()


def file_digest(path: Path) -> str:
    digest = hashlib.md5()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def image_files(folder: Path):
    return sorted(
        f for f in folder.iterdir() if f.is_file() and f.suffix.lower() in ALLOWED_EXTENSIONS
    )


def iter_source_entries(source: Path):
    """
    Hasilkan (split, kelas, path) dari satu folder sumber.

    Mendukung struktur per-kelas dan struktur flat (label dari nama file).
    """
    for split_dir in sorted(p for p in source.iterdir() if p.is_dir()):
        split = normalize_split(split_dir.name)
        if split is None:
            print(f"  Lewati folder split tidak dikenal: {split_dir.name}")
            continue

        # Bentuk 1: subfolder kelas.
        class_dirs = [p for p in split_dir.iterdir() if p.is_dir()]
        found_class_dirs = False
        for class_dir in sorted(class_dirs):
            class_name = normalize_class(class_dir.name)
            if class_name is None:
                print(f"  Lewati folder kelas tidak dikenal: {split_dir.name}/{class_dir.name}")
                continue
            found_class_dirs = True
            for file in image_files(class_dir):
                yield split, class_name, file

        if found_class_dirs:
            continue

        # Bentuk 2: file gambar langsung di folder split (flat Roboflow).
        flat_files = image_files(split_dir)
        if flat_files:
            unknown = 0
            for file in flat_files:
                class_name = class_from_filename(file.name)
                if class_name is None:
                    unknown += 1
                    continue
                yield split, class_name, file
            if unknown:
                print(f"  {split_dir.name}: {unknown} file tanpa prefix kelas dikenali (dilewati)")


def collect_hash_groups(dest: Path) -> dict[str, list[Path]]:
    """Kelompokkan semua file gambar berdasarkan hash isi."""
    groups: dict[str, list[Path]] = defaultdict(list)
    for split_dir in sorted(p for p in dest.iterdir() if p.is_dir()):
        if normalize_split(split_dir.name) is None:
            continue
        for class_dir in sorted(p for p in split_dir.iterdir() if p.is_dir()):
            for file in image_files(class_dir):
                groups[file_digest(file)].append(file)
    return groups


def dedupe_dataset(dest: Path) -> int:
    """
    Hapus gambar duplikat berbasis hash isi.

    Prioritas file yang DIPERTAHANKAN: test > val > train.
    Artinya gambar yang muncul di test/val akan dihapus dari train
    (mencegah kebocoran data), dan duplikat dalam satu split disisakan satu.
    """
    priority = {"test": 0, "val": 1, "train": 2}
    class_priority = {name: index for index, name in enumerate(CLASS_NAMES)}
    removed = 0
    groups = collect_hash_groups(dest)

    for files in groups.values():
        if len(files) < 2:
            continue
        ordered = sorted(
            files,
            key=lambda p: (
                priority.get(p.relative_to(dest).parts[0], 99),
                class_priority.get(p.relative_to(dest).parts[1], 99),
                p.name,
            ),
        )
        for duplicate in ordered[1:]:
            duplicate.unlink()
            removed += 1

    print(f"\n=== Deduplikasi (MD5) ===\nFile duplikat dihapus: {removed}")
    return removed


def count_dataset(dest: Path) -> tuple[dict[str, dict[str, int]], int]:
    counts: dict[str, dict[str, int]] = {split: {name: 0 for name in CLASS_NAMES} for split in SPLITS}
    total = 0
    for split_dir in sorted(p for p in dest.iterdir() if p.is_dir()):
        split = normalize_split(split_dir.name)
        if split is None:
            continue
        for class_dir in sorted(p for p in split_dir.iterdir() if p.is_dir()):
            class_name = normalize_class(class_dir.name) or class_dir.name.lower()
            count = len(image_files(class_dir))
            counts[split][class_name] = counts[split].get(class_name, 0) + count
            total += count
    return counts, total


def check_leaks(dest: Path, max_examples: int = 8) -> bool:
    """
    Deteksi kebocoran data berbasis hash isi file sekaligus menulis leak_report.txt.

    Kebocoran = gambar identik muncul di lebih dari satu split (train/val/test)
    atau muncul lebih dari sekali di split+kelas yang sama.
    """
    if not dest.is_dir():
        raise SystemExit(f"Folder dataset tidak ditemukan: {dest}")

    by_hash: dict[str, list[tuple[str, str, str]]] = defaultdict(list)
    total_files = 0
    for split_dir in sorted(p for p in dest.iterdir() if p.is_dir()):
        split = normalize_split(split_dir.name)
        if split is None:
            continue
        for class_dir in sorted(p for p in split_dir.iterdir() if p.is_dir()):
            class_name = normalize_class(class_dir.name) or class_dir.name.lower()
            for file in image_files(class_dir):
                total_files += 1
                by_hash[file_digest(file)].append((split, class_name, file.name))

    cross_split: list[list[tuple[str, str, str]]] = []
    same_split: list[list[tuple[str, str, str]]] = []
    for occurrences in by_hash.values():
        if len(occurrences) < 2:
            continue
        splits = {item[0] for item in occurrences}
        if len(splits) > 1:
            cross_split.append(occurrences)
        else:
            same_split.append(occurrences)

    unique = len(by_hash)
    leaked_images = sum(len(items) for items in cross_split)
    duplicate_images = sum(len(items) - 1 for items in same_split)
    counts, total_counted = count_dataset(dest)

    print("\n=== Pemeriksaan kebocoran data (hash MD5) ===")
    print(f"Total file          : {total_files}")
    print(f"Gambar unik         : {unique}")
    print(f"Duplikat lintas split: {len(cross_split)} grup ({leaked_images} file)")
    print(f"Duplikat dalam split : {len(same_split)} grup ({duplicate_images} file berlebih)")

    for title, groups in (("LINTAS SPLIT", cross_split), ("DALAM SPLIT", same_split)):
        if not groups:
            continue
        print(f"\nContoh duplikat {title}:")
        for group in groups[:max_examples]:
            locations = ", ".join(f"{s}/{c}/{n}" for s, c, n in group)
            print(f"  - {locations}")

    report_path = dest / "leak_report.txt"
    lines = [
        "Laporan dataset & kebocoran data (hash MD5)",
        f"Total file            : {total_files} (terhitung: {total_counted})",
        f"Gambar unik           : {unique}",
        f"Duplikat lintas split : {len(cross_split)} grup ({leaked_images} file)",
        f"Duplikat dalam split  : {len(same_split)} grup ({duplicate_images} file berlebih)",
        "",
        "Komposisi dataset:",
    ]
    for split in SPLITS:
        detail = ", ".join(f"{name}={counts[split].get(name, 0)}" for name in CLASS_NAMES)
        lines.append(f"  {split:5s}: {sum(counts[split].values()):5d} ({detail})")
    lines.append("")

    for title, groups in (("LINTAS SPLIT", cross_split), ("DALAM SPLIT", same_split)):
        if not groups:
            continue
        lines.append(f"[{title}]")
        for group in groups:
            lines.append("  " + " | ".join(f"{s}/{c}/{n}" for s, c, n in group))
        lines.append("")
    report_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"\nLaporan lengkap: {report_path.resolve()}")

    return not cross_split and not same_split


def prepare(sources: list[Path], dest: Path, clean: bool) -> None:
    for source in sources:
        if not source.is_dir():
            raise SystemExit(f"Folder sumber tidak ditemukan: {source}")

    if clean and dest.exists():
        print(f"Menghapus folder tujuan lama: {dest}")
        shutil.rmtree(dest)

    total_copied = 0
    total_skipped = 0
    summary: dict[str, dict[str, int]] = {split: {name: 0 for name in CLASS_NAMES} for split in SPLITS}

    for source in sources:
        print(f"\n=== Sumber: {source} ===")
        source_copied = 0
        for split, class_name, file in iter_source_entries(source):
            if is_duplicate(file):
                total_skipped += 1
                continue

            target_dir = dest / split / class_name
            target_dir.mkdir(parents=True, exist_ok=True)

            target = target_dir / file.name
            counter = 1
            while target.exists():
                target = target_dir / f"{file.stem}_{counter}{file.suffix}"
                counter += 1

            shutil.copy2(file, target)
            summary[split][class_name] += 1
            source_copied += 1
            total_copied += 1

        print(f"  Disalin: {source_copied} gambar")

    print("\n=== Ringkasan penyalinan ===")
    for split in SPLITS:
        classes = summary[split]
        total = sum(classes.values())
        detail = ", ".join(f"{k}={v}" for k, v in classes.items())
        print(f"{split:5s}: {total:5d} gambar ({detail})")

    print(f"\nTotal disalin : {total_copied}")
    print(f"Total dilewati: {total_skipped} (nama mengandung 'copy')")
    print(f"Tujuan        : {dest.resolve()}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Siapkan dataset Skinly 4 kelas untuk training")
    parser.add_argument(
        "--source",
        nargs="+",
        default=None,
        help="Satu atau beberapa folder dataset sumber (train/valid/test, per-kelas atau flat)",
    )
    parser.add_argument(
        "--dest",
        default="dataset",
        help="Folder tujuan (default: dataset, relatif terhadap folder backend)",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Hapus folder tujuan terlebih dahulu sebelum menyalin",
    )
    parser.add_argument(
        "--dedupe",
        action="store_true",
        help="Hapus duplikat setelah menyalin (default aktif saat --source dipakai)",
    )
    parser.add_argument(
        "--no-dedupe",
        action="store_true",
        help="Jangan hapus duplikat setelah menyalin",
    )
    parser.add_argument(
        "--check-leak",
        action="store_true",
        help="Tulis laporan kebocoran data (default aktif saat --source dipakai)",
    )
    parser.add_argument(
        "--no-check-leak",
        action="store_true",
        help="Jangan periksa/tulis laporan kebocoran",
    )
    args = parser.parse_args()

    dest = Path(args.dest)
    source_paths = [Path(item) for item in args.source] if args.source else []
    if not source_paths and not (args.check_leak or args.dedupe):
        # Auto-deteksi folder dataset bawaan proyek jika --source tidak ditentukan
        for candidate in [
            Path("../Oily-Dry-Normal-Combination-Skin-Types"),
            Path("Oily-Dry-Normal-Combination-Skin-Types"),
            Path("../../Oily-Dry-Normal-Combination-Skin-Types"),
        ]:
            if candidate.is_dir():
                print(f"Menggunakan dataset bawaan proyek: {candidate.resolve()}")
                source_paths = [candidate]
                break

    if source_paths:
        prepare(source_paths, dest, args.clean)
        if not args.no_dedupe:
            dedupe_dataset(dest)
        if not args.no_check_leak:
            check_leaks(dest)
    elif not (args.check_leak or args.dedupe):
        raise SystemExit("--source wajib diisi (kecuali memakai --check-leak/--dedupe).")
    else:
        if args.dedupe:
            dedupe_dataset(dest)
        if args.check_leak:
            check_leaks(dest)


if __name__ == "__main__":
    main()
