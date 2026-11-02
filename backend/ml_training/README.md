# Panduan Dataset untuk Training Model Skinly

## Tentang Model
Skinly menggunakan **MobileNetV2** dengan transfer learning dari pretrained ImageNet untuk mengklasifikasikan 4 jenis kulit:
- **Normal** - Kulit seimbang
- **Oily** - Kulit berminyak
- **Dry** - Kulit kering
- **Combination** - Kulit kombinasi

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

## Sumber Dataset Publik

### 1. OILY-DRY-NORMAL Skin Types Dataset (Kaggle)
**Direkomendasikan** - Dataset sudah diberi label dan tersedia publik.
- URL: https://www.kaggle.com/datasets/shakyadissanayake/oily-dry-and-normal-skin-types-dataset
- Berisi 3 kelas: oily, dry, normal
- Tambahkan kelas `combination` dari sumber lain atau buat sendiri

### 2. Skin Type Dataset (Roboflow)
- URL: https://universe.roboflow.com/skin-type
- Tersedia beberapa dataset labeled untuk skin type detection

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
| Train | 500-1000+ | 2000-4000+ |
| Val   | 100-200   | 400-800   |
| Test  | 100-200   | 400-800   |

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

# 2. Pergi ke folder backend
cd backend

# 3. Pastikan dataset sudah ada di backend/dataset/
# (lihat struktur di atas)

# 4. Jalankan training
python ml_training/train.py

# 5. Model akan disimpan otomatis ke:
#    backend/app/ml/skin_model.keras
#    backend/app/ml/class_names.json
```

Training membutuhkan waktu bervariasi:
- Tanpa GPU: 30-60 menit (tergantung ukuran dataset)
- Dengan GPU (NVIDIA): 5-15 menit

## Dependensi Tambahan (Opsional)

Untuk laporan evaluasi lengkap (confusion matrix):
```bash
pip install scikit-learn matplotlib seaborn
```

## Tips Training

1. **Augmentasi data**: Script sudah menyertakan augmentasi (flip, rotasi, zoom, brightness)
2. **Transfer learning**: MobileNetV2 pretrained ImageNet sangat membantu meski dataset kecil
3. **Early stopping**: Training otomatis berhenti jika val_accuracy tidak membaik dalam 5 epoch
4. **Checkpoint**: Model terbaik disimpan otomatis, bukan yang terakhir

## Catatan Privasi

Dataset foto wajah mengandung data pribadi. Pastikan:
- Menggunakan dataset dengan lisensi yang sesuai
- Mendapat persetujuan dari subjek foto jika mengumpulkan sendiri
- Tidak menyebarkan dataset foto wajah tanpa izin
