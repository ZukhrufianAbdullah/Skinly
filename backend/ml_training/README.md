# Panduan Dataset untuk Training Model Skinly

## Tentang Model
Skinly menggunakan **MobileNetV2** (default) atau **EfficientNetB0** (opsional) dengan transfer learning dari pretrained ImageNet untuk mengklasifikasikan **4 kelas**:
- **Normal** - Kulit seimbang
- **Oily** - Kulit berminyak
- **Dry** - Kulit kering
- **Combination** - Kulit kombinasi (T-zone berminyak, pipi kering)

Kelas **Combination** kini **dilatih langsung** sebagai kelas keempat. Keputusan akhir memakai **rule-v3**: argmax softmax atas keempat kelas. `combination_score` = probabilitas kelas combination, dan `confidence` = probabilitas kelas terpilih.

> Model lama 3 kelas masih kompatibel. Jika `class_names.json` hanya berisi `dry/normal/oily`, backend otomatis memakai rule-v2 (`combination_score = 2 * min(P(dry), P(oily))`).

## Struktur Dataset

```
backend/dataset/
├── train/
│   ├── combination/    ← Foto kulit kombinasi untuk training
│   ├── dry/            ← Foto kulit kering untuk training
│   ├── normal/         ← Foto kulit normal untuk training
│   └── oily/           ← Foto kulit berminyak untuk training
├── val/
│   ├── combination/
│   ├── dry/
│   ├── normal/
│   └── oily/
└── test/
    ├── combination/
    ├── dry/
    ├── normal/
    └── oily/
```

Nama split `valid` juga didukung (otomatis diperlakukan sebagai `val`), dan nama kelas boleh berhuruf besar (`Combination`, `Dry`, `Normal`, `Oily`) saat masih di folder sumber — skrip persiapan akan menormalkannya.

Skrip persiapan juga mendukung **folder flat ala Roboflow**, yaitu gambar langsung berada di `train/`, `valid/`, `test/` dengan label di prefix nama file (`combination_-_xxx.jpg`, `dry_-_xxx.jpg`, dst.).

## Sumber Dataset Publik

### 1. Oily-Dry-Normal-Combination Skin Types Dataset (Kaggle)
**Direkomendasikan** - Dataset sudah diberi label dan tersedia publik.
- URL: https://www.kaggle.com/datasets/shakyadissanayake/oily-dry-and-normal-skin-types-dataset
- Berisi 4 kelas: oily, dry, normal, combination
- Struktur folder: `train/`, `valid/`, `test/` masing-masing berisi `Combination/`, `Dry/`, `Normal/`, `Oily/`

### 2. Skin Type Dataset (Roboflow)
- URL: https://universe.roboflow.com/skin-type
- Struktur flat: gambar di `train/`, `valid/`, `test/` dengan label pada prefix nama file
- Tambahan bagus untuk memperkuat kelas `combination`

### 3. ISIC Archive (dermoscopy images)
- URL: https://www.isic-archive.com/
- Dataset kulit medis dengan kualitas tinggi (butuh adaptasi)

### 4. DermNet NZ
- URL: https://dermnetnz.org/
- Gambar kondisi kulit dengan lisensi untuk penelitian

## Ketentuan Foto yang Baik

Foto yang bagus untuk training:
- ✅ Wajah menghadap depan (frontal)
- ✅ Pencahayaan alami atau indoor yang merata
- ✅ Fokus tajam pada area kulit wajah
- ✅ Tanpa filter atau efek berlebihan
- ✅ Resolusi minimal 224x224 piksel (lebih besar lebih baik)

Foto yang DIHINDARI:
- ❌ Buram atau out of focus
- ❌ Terlalu gelap atau overexposed
- ❌ Dengan makeup tebal yang menutupi kondisi kulit
- ❌ Wajah miring lebih dari 45 derajat
- ❌ Filter kamera yang mengubah tekstur kulit

## Jumlah Data yang Disarankan

| Split | Per Kelas | Total |
|-------|-----------|-------|
| Train | 500-1000+ | 1500-3000+ |
| Val   | 100-200   | 300-600   |
| Test  | 100-200   | 300-600   |

Semakin banyak data, semakin baik akurasi model. Minimal 200 gambar per kelas untuk hasil yang dapat diandalkan.

## Cara Membagi Dataset

Jika kamu hanya memiliki satu folder data (belum terbagi):

```python
# Script helper untuk membagi dataset
import os, shutil, random
from pathlib import Path

def split_dataset(source_dir, output_dir, ratios=(0.7, 0.15, 0.15), seed=42):
    random.seed(seed)
    splits = ["train", "val", "test"]
    
    for class_name in os.listdir(source_dir):
        class_path = Path(source_dir) / class_name
        if not class_path.is_dir():
            continue
            
        images = list(class_path.glob("*.jpg")) + list(class_path.glob("*.png"))
        random.shuffle(images)
        
        n = len(images)
        n_train = int(n * ratios[0])
        n_val = int(n * ratios[1])
        
        splits_data = {
            "train": images[:n_train],
            "val": images[n_train:n_train+n_val],
            "test": images[n_train+n_val:],
        }
        
        for split, split_images in splits_data.items():
            out_dir = Path(output_dir) / split / class_name
            out_dir.mkdir(parents=True, exist_ok=True)
            for img in split_images:
                shutil.copy(img, out_dir / img.name)

# Penggunaan:
# split_dataset("raw_dataset", "dataset")
```

## Cara Menjalankan Training

```bash
# 1. Aktifkan environment
conda activate skinly

# 2. Install TensorFlow (tidak termasuk requirements.txt)
pip install tensorflow==2.21.0

# 3. Pergi ke folder backend
cd backend

# 4. Siapkan dataset: gabungkan semua sumber, buang duplikat, tulis leak report
python ml_training/prepare_dataset.py --source "C:/path/dataset-utama" "C:/path/Skin Type.v1i.multiclass" --dest dataset --clean

# 4b. Periksa ulang kebocoran (opsional, prioritas test > val > train)
python ml_training/prepare_dataset.py --check-leak --dest dataset

# 5. Jalankan training (default MobileNetV2)
python ml_training/train.py

# Opsional: atur durasi training
python ml_training/train.py --epochs-phase1 5 --epochs-phase2 3

# Opsional: coba backbone EfficientNetB0
python ml_training/train.py --backbone efficientnetb0

# Opsional: lewati kalibrasi temperature scaling
python ml_training/train.py --no-calibration

# 6. Model akan disimpan otomatis ke:
#    backend/app/ml/skin_model.keras
#    backend/app/ml/class_names.json
#    backend/app/ml/model_meta.json      (backbone, preprocessing, rule_version)
#    backend/app/ml/calibration.json     (temperature, ECE sebelum/sesudah)
#    backend/app/ml/evaluation_report_*.txt
#    backend/app/ml/training_summary_*.json
```

Training berjalan dua fase:
1. **Fase 1** — base model dibekukan, hanya head klasifikasi yang dilatih.
2. **Fase 2** — fine-tuning `30` layer terakhir dengan learning rate kecil. BatchNormalization tetap dibekukan agar stabil.

Pemilihan model terbaik, early stopping, dan checkpoint memakai **macro-F1 pada val set** (bukan accuracy), sehingga kelas minoritas (mis. `oily`) tidak diabaikan.

Setelah selesai, restart backend (`uvicorn app.main:app --reload`). Cek `GET /api/v1/health` dan pastikan `model_loaded: true` serta `demo_mode: false`.

Training membutuhkan waktu bervariasi:
- Tanpa GPU: 30-60 menit (tergantung ukuran dataset)
- Dengan GPU (NVIDIA): 5-15 menit

## Dependensi Tambahan (Opsional)

Untuk laporan evaluasi lengkap (confusion matrix):
```bash
pip install scikit-learn matplotlib seaborn
```

## Tips Training

1. **Cek kebocoran data**: selalu jalankan `--check-leak` setelah menyiapkan dataset. Gambar identik di train dan test membuat skor evaluasi palsu.
2. **Class weighting**: diterapkan otomatis berdasarkan jumlah gambar per kelas di train.
3. **Augmentasi data**: flip, rotasi, zoom, translasi, brightness, dan contrast diterapkan pada gambar mentah (0-255) sebelum preprocessing backbone.
4. **Transfer learning**: MobileNetV2 pretrained ImageNet cukup ringan; EfficientNetB0 bisa dicoba jika target macro-F1 belum tercapai.
5. **Early stopping & checkpoint**: monitor `val_macro_f1`, bukan `val_accuracy`.
6. **Kalibrasi**: temperature scaling dicari pada val set untuk menurunkan ECE. Nilai temperature dipakai otomatis oleh `app/ml/inference.py`.
7. **Evaluasi**: lihat `evaluation_report_*.txt` untuk classification report dan confusion matrix 4 kelas (`combination`, `dry`, `normal`, `oily`).

## Catatan Privasi

Dataset foto wajah mengandung data pribadi. Pastikan:
- Menggunakan dataset dengan lisensi yang sesuai
- Mendapat persetujuan dari subjek foto jika mengumpulkan sendiri
- Tidak menyebarkan dataset foto wajah tanpa izin
