# Laporan Evaluasi Model Skinly

Dokumen ini dihasilkan otomatis oleh `ml_training/make_report.py` dari
artefak training. Jangan diedit manual; jalankan ulang skrip setelah training.

## Ringkasan

Model aktif: **app/ml** (MobileNetV2), dibuat `20261115_094632`.

Model mengklasifikasikan **3 kelas dasar** (`dry`, `normal`, `oily`). `combination` **tidak** dilatih sebagai kelas terpisah; ia diturunkan saat
inferensi dengan **rule-v2**:

```
combination_score = 2 * min(P(dry), P(oily))
is_combination     = combination_score >= COMBINATION_SCORE_THRESHOLD  # default 0.50
```

## Model: app/ml

- **Backbone**: MobileNetV2 (`mobilenetv2`)
- **Kelas**: dry, normal, oily
- **Ukuran input**: 224 × 224 piksel
- **Aturan kombinasi**: `combination_score = 2 * min(P(dry), P(oily))` (rule-v2)
- **Artefak**: `app/ml/training_summary_20261115_094632.json`

### Metrik test

| Metrik | Nilai |
| --- | --- |
| Accuracy | 0.4286 |
| Macro-F1 | 0.4263 |
| Loss | 1.0997 |
| Macro-F1 val terbaik | 0.4240 |

### Kalibrasi

| Metrik | Nilai |
| --- | --- |
| Metode | temperature_scaling |
| Temperature | 4.90 |
| ECE sebelum | 0.1903 |
| ECE sesudah | 0.0973 |

### Metrik per kelas

| Kelas | Precision | Recall | F1 | Support |
| --- | --- | --- | --- | --- |
| dry | 0.2885 | 0.4286 | 0.3448 | 35 |
| normal | 0.5098 | 0.4483 | 0.4771 | 58 |
| oily | 0.5333 | 0.4000 | 0.4571 | 40 |

### Confusion matrix

| Aktual \ Prediksi | dry | normal | oily |
| --- | --- | --- | --- |
| **dry** | 15 | 13 | 7 |
| **normal** | 25 | 26 | 7 |
| **oily** | 12 | 12 | 16 |

### Trigger kombinasi (rule-v2)

| Threshold skor kombinasi | Persentase test set |
| --- | --- |
| 0.40 | 36.8% |
| 0.45 | 30.8% |
| 0.50 **(default)** | 27.8% |
| 0.55 | 23.3% |
| 0.60 | 14.3% |

### Komposisi dataset

| Split | dry | normal | oily | Total |
| --- | --- | --- | --- | --- |
| train | 1052 | 1030 | 1014 | 3096 |
| val | 71 | 107 | 80 | 258 |
| test | 35 | 58 | 40 | 133 |

### Status target

| Target | Ambang | Hasil | Status |
| --- | --- | --- | --- |
| Macro-F1 test | >= 0.6 | 0.4263 | FAIL |
| Recall kelas dry | >= 0.45 | 0.4286 | FAIL |
| ECE setelah kalibrasi | < 0.1 | 0.0973 | PASS |

## Keterbatasan & catatan

- Dataset test hanya berisi 133 gambar (dry 35, normal 58, oily 40). Selisih beberapa poin persentase belum tentu signifikan secara statistik.
- Foto berasal dari dataset publik dengan kondisi pencahayaan dan kamera terbatas; performa pada foto pengguna nyata bisa berbeda.
- Kelas `combination` tidak memiliki label ground truth, sehingga aturan rule-v2 adalah **kecenderungan**, bukan diagnosis medis.
- Target awal (macro-F1 ≥ 0.60, recall dry ≥ 0.45) mungkin belum tercapai. Jika status `FAIL`, lihat tabel status target di atas dan bagian "Penyebab & rencana perbaikan" di bawah.

## Penyebab target belum tercapai (jika ada)

1. **Kualitas label dataset**: gambar `dry`/`normal` sering sulit dibedakan secara visual (sama-sama tidak berminyak), sehingga batas kelas kabur.
2. **Domain foto**: dataset berisi foto close-up wajah dengan variasi pencahayaan besar; model harus memisahkan tekstur halus.
3. **Ukuran test kecil**: 133 gambar membuat metrik berfluktuasi.
4. **Data imbalance sebelumnya**: sebelum penambahan data `oily`, kelas minoritas membuat recall `oily` rendah. Setelah penyeimbangan, latih ulang dan bandingkan.

Rencana perbaikan lanjutan (di luar cakupan iterasi ini):

- Uji backbone lain (EfficientNetB0/B3) dan bandingkan pada test set yang sama.
- Tambah data `dry`/`normal` yang benar-benar ambigu (mis. kulit kombinasi).
- Terapkan label smoothing atau mixup untuk meredam label noise.
- Kumpulkan test set lokal dari pengguna nyata dengan label dermatologis.

## Penggunaan yang disarankan

Skinly adalah alat bantu edukasi perawatan kulit, **bukan** pengganti diagnosis dokter. Tampilkan selalu probabilitas per kelas dan ingatkan pengguna bahwa hasil dapat salah. Jangan gunakan untuk keputusan medis.
