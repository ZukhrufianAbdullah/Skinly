# Skinly - Aplikasi Pendeteksi Jenis Kulit Wajah

Skinly adalah aplikasi mobile modern berbasis **Machine Learning** yang mendeteksi jenis kulit wajah (**Normal**, **Oily**, **Dry**, **Combination**) menggunakan model **MobileNetV2** dengan Transfer Learning. Proyek ini dilengkapi backend REST API berbasis **FastAPI** dan aplikasi mobile berbasis **Flutter**.

---

## 🌟 Fitur Utama

- **Deteksi 4 Kelas Kulit**: Model MobileNetV2 dilatih langsung pada 4 kelas (*Normal, Oily, Dry, Combination*) dengan aturan keputusan **rule-v3** (`argmax` softmax). Respons menyertakan `confidence`, probabilitas keempat kelas, `raw_probabilities`, `combination_score` (= probabilitas kelas *combination*), `is_combination`, dan `rule_version`. Model lama 3 kelas tetap didukung lewat **rule-v2** (`combination_score = 2 × min(P(dry), P(oily))`).
- **Validasi Kualitas Citra Otomatis**: Memastikan foto layak sebelum diproses model dengan memeriksa batas kecerahan minimum (menolak foto gelap), ketajaman (*Laplacian variance* - menolak foto blur), dan verifikasi wajah manusia (deteksi mata & hidung via Haar Cascade).
- **Panduan Foto Scan (*Scan Example*)**: Panduan visual komparasi foto wajah yang benar vs salah (pencahayaan, posisi wajah, tanpa makeup tebal/kacamata/filter) untuk hasil optimal.
- **Rekomendasi Skincare Lengkap**: Informasi karakteristik tipe kulit, panduan rutinitas perawatan pagi (*AM Routine*) & malam (*PM Routine*), rekomendasi bahan aktif (*Key Ingredients*), serta bahan yang perlu dihindari.
- **Sistem Autentikasi JWT**: Registrasi dan login akun aman dengan enkripsi password `bcrypt` serta token JWT tersimpan terenkripsi di *Android Keystore* / *iOS Keychain* via `flutter_secure_storage`.
- **Isolasi Riwayat & Manajemen Scan**: Setiap pengguna memiliki riwayat pemindaian pribadi, tampilan detail hasil scan masa lalu, dan kemampuan menghapus data scan beserta file fotonya di server.
- **Edukasi & Artikel Interaktif**: Artikel panduan perawatan kulit wajah dengan fitur pencarian judul/konten secara langsung (*real-time search*) dan filter kategori.
- **Sistem Feedback Pengguna**: Formulir rating kepuasan (1-5 bintang), pemilihan kategori (*Bug, Feature, Accuracy, UI/UX, Other*), dan catatan saran/masukan pengguna.
- **Profil Akun & Ringkasan Pengguna**: Halaman profil menampilkan data akun, ringkasan total scan & jenis kulit terakhir, dialog informasi aplikasi, dan konfirmasi logout aman.
- **Desain UI Figma & Micro-Animations**: Mengusung palet warna Teal (`#6CC9BF`/`#327E76`) dan Pink aksen (`#F76A9B`), tipografi Google Fonts (*Fredoka* untuk judul & *Poppins* untuk teks), maskot bunga Skinly interaktif, *curved bottom navigation*, dan transisi layar halus.

---

## 🏗️ Struktur Proyek

```
skinly/
├── .gitignore               # Root git ignore (mengabaikan secrets, virtual env, & build)
├── README.md                # Dokumentasi proyek
├── mobile/                  # Aplikasi Flutter (Android & iOS)
│   ├── assets/              # Aset visual (images, icons, illustration)
│   ├── lib/
│   │   ├── main.dart        # Entry point Flutter
│   │   ├── core/            # Theme, router, network (Dio + JWT), reusable widgets
│   │   └── features/        # Modul fitur:
│   │       ├── auth/        # Login, register, auth controller & storage
│   │       ├── home/        # Dashboard beranda, tips harian, maskot bunga
│   │       ├── scan/        # Kamera, pick galeri, panduan contoh foto
│   │       ├── result/      # Hasil deteksi, routine tab, rekomendasi bahan
│   │       ├── history/     # Riwayat scan per user & detail riwayat
│   │       ├── knowledge/   # Artikel edukasi, pencarian, & filter kategori
│   │       ├── feedback/    # Formulir rating & ulasan pengguna
│   │       ├── profile/     # Info akun, statistik scan, dialog logout
│   │       ├── onboarding/  # Layar pengenalan aplikasi
│   │       └── splash/      # Layar splash & inisialisasi sesi
│   └── test/                # Unit test token tema, model serializer, & widget test
└── backend/                 # Python FastAPI Backend
    ├── app/
    │   ├── main.py          # Entry point FastAPI & route mounting
    │   ├── core/            # Database engine, env configuration, logging
    │   ├── api/
    │   │   ├── deps.py      # Dependency injection & JWT token verification
    │   │   └── v1/          # Endpoints: auth, scans, articles, feedback, health, ml
    │   ├── models/          # Model tabel database SQLAlchemy (users, scans, dll)
    │   ├── schemas/         # Skema validasi request & response (Pydantic v2)
    │   ├── services/        # Validator kualitas citra (kecerahan, blur, Haar cascade)
    │   └── ml/              # Service inferensi model Keras + class names
    ├── alembic/             # Skrip migrasi database
    ├── ml_training/         # Skrip training MobileNetV2 + dokumentasi dataset
    ├── scripts/             # SQL setup awal & skrip seeding artikel/tipe kulit
    ├── tests/               # Unit & integration tests pytest
    ├── .env.example         # Template konfigurasi environment backend
    └── requirements.txt     # Daftar dependensi Python backend
```

---

## ⚡ FASE 1: Setup Backend (FastAPI + MySQL)

### Prasyarat
- **Python 3.12** (disarankan menggunakan [Miniconda](https://docs.anaconda.com/miniconda/) atau Anaconda)
- **MySQL Server** via **Laragon** ATAU **XAMPP** (pilih salah satu)
- **Git**

> ⚠️ **PENTING**: Jangan jalankan Laragon dan XAMPP secara bersamaan karena keduanya memperebutkan port default MySQL (3306).

---

### Langkah 1: Setup Environment Python & Dependensi

Buka terminal di root proyek, masuk ke folder `backend`, buat environment baru, dan install dependensinya:

```bash
cd backend

# Buat environment conda bernama 'skinly' dengan Python 3.12
conda create -n skinly python=3.12 -y

# Aktifkan environment
conda activate skinly

# Install seluruh dependensi backend
pip install -r requirements.txt
```

---

### Langkah 2: Nyalakan MySQL

**Opsi Laragon:**
1. Buka Laragon.
2. Klik **"Start All"** (atau klik menu Start pada MySQL).
3. Pastikan status MySQL sudah berjalan (*running*).

**Opsi XAMPP:**
1. Buka XAMPP Control Panel.
2. Klik tombol **"Start"** pada baris MySQL.
3. Status berubah menjadi hijau (Port 3306).

---

### Langkah 3: Buat Database

Eksekusi skrip `backend/scripts/create_database.sql` untuk membuat database `skinly` dan `skinly_test`.

**Via Terminal / MySQL CLI (Laragon):**
```bash
# Dari folder backend/
mysql -u root -p < scripts/create_database.sql
# Tekan Enter jika password MySQL kosong (default Laragon/XAMPP)
```

**Via phpMyAdmin / HeidiSQL (XAMPP / Laragon):**
1. Buka browser: `http://localhost/phpmyadmin` (atau buka HeidiSQL).
2. Buka tab **SQL**.
3. Buka file `backend/scripts/create_database.sql`, salin seluruh isinya, dan klik **Go** / **Execute**.
4. Database `skinly` dan `skinly_test` akan otomatis terbuat.

---

### Langkah 4: Konfigurasi File Environment (`.env`)

Salin file contoh konfigurasi `.env.example` menjadi `.env`:

```bash
# Pastikan berada di folder backend/
copy .env.example .env
```

Buka dan periksa file `.env`. Secara default sudah disesuaikan untuk Laragon/XAMPP:

```env
# Database MySQL
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=          # Biarkan kosong jika tidak memakai password
DB_NAME=skinly
DB_TEST_NAME=skinly_test

# Konfigurasi JWT Authentication
JWT_SECRET_KEY=skinly-super-secret-key-change-in-production-2026
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=10080
```

> Sesuaikan `DB_PASSWORD` atau `DB_PORT` jika konfigurasi MySQL lokal Anda berbeda.

---

### Langkah 5: Jalankan Migrasi Database (Alembic)

Jalankan perintah berikut untuk membuat struktur tabel database secara otomatis:

```bash
# Pastikan environment aktif: conda activate skinly
alembic upgrade head
```

Output yang berhasil akan menampilkan eksekusi migrasi:
```
INFO  [alembic.runtime.migration] Running upgrade  -> 001_initial, Buat tabel awal Skinly
INFO  [alembic.runtime.migration] Running upgrade 001_initial -> 002_add_users_and_auth, Tambah tabel users dan autentikasi
```

---

### Langkah 6: Isi Data Awal (*Seed Data*)

Jalankan skrip seed untuk mengisi informasi tipe kulit dan artikel edukasi:

```bash
python scripts/seed.py
```

Output yang diharapkan:
```
🌱 Memulai proses seed data Skinly...
📊 Mengisi data skin_type_info...
  ✅ Tambah: normal
  ✅ Tambah: oily
  ✅ Tambah: dry
  ✅ Tambah: combination
📚 Mengisi data artikel edukasi...
  ✅ Tambah: Kenali 4 Jenis Kulit Wajah: Karakteristik dan Cara Merawatnya
  ... (10 artikel edukasi)
✅ Seed selesai! Database Skinly siap digunakan.
```

---

### Langkah 7: Jalankan Server Backend

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

- Buka **http://localhost:8000/docs** pada browser untuk mengakses dokumentasi interaktif Swagger UI.
- Endpoint kesehatan sistem dapat diuji di **http://localhost:8000/health**.

> 💡 **Informasi Mode Demo**: Jika model `app/ml/skin_model.keras` belum dilatih, backend tetap dapat berjalan normal dalam **Mode Demo**. Respons prediksi akan menyertakan flag `"demo": true`.

---

### Langkah 8: Menjalankan Pengujian Backend (*Testing*)

Pastikan MySQL menyala dan database `skinly_test` sudah dibuat pada Langkah 3:

```bash
pytest tests/ -v
```

---

## 🤖 FASE 2: Pelatihan Model Machine Learning

Model dilatih dengan **MobileNetV2 Transfer Learning** untuk **4 kelas**: `combination`, `dry`, `normal`, `oily`. Keputusan akhir memakai aturan **rule-v3** (argmax softmax). Model lama 3 kelas masih kompatibel dan otomatis memakai **rule-v2** (`combination_score = 2 × min(P(dry), P(oily))`, lihat `COMBINATION_SCORE_THRESHOLD` di `.env`).

Pipeline training versi ini juga menambahkan:
- **Class weighting** untuk menyeimbangkan kelas `combination`/`dry`/`normal`/`oily`.
- **Augmentasi lebih kuat** (flip, rotasi, zoom, translasi, brightness, contrast).
- **Seleksi model & early stopping berbasis macro-F1**, bukan accuracy.
- **Kalibrasi temperature scaling** agar `confidence` lebih jujur (ECE turun).
- **Opsi backbone** `mobilenetv2` (default) atau `efficientnetb0`.

### Langkah 1: Install TensorFlow

TensorFlow sengaja tidak dipasang otomatis oleh `requirements.txt`. Install dependensi training ke environment `skinly`:

```bash
conda activate skinly
pip install -r ml_training/requirements-train.txt
```

### Langkah 2: Siapkan Dataset

Dataset publik *Oily-Dry-Normal-Combination Skin Types* memiliki struktur `train/`, `valid/`, `test/` dengan folder kelas `Combination`, `Dry`, `Normal`, `Oily`. Dataset tambahan dari Roboflow (`Skin Type.v1i.multiclass`) memakai folder flat dengan label di prefix nama file. Skrip persiapan mendukung keduanya sekaligus, menggabungkan banyak sumber, membuang duplikat, dan menulis laporan kebocoran:

```bash
cd backend
python ml_training/prepare_dataset.py \
  --source "C:/Polinema/SEMESTER 5/PBL/archive/Oily-Dry-Normal-Combination-Skin-Types" \
           "C:/Polinema/SEMESTER 5/PBL/Skin Type.v1i.multiclass" \
  --dest dataset --clean
```

Deduplikasi berbasis hash MD5 otomatis berjalan dengan prioritas **test > val > train**. Hasil akhirnya harus menampilkan `Duplikat lintas split: 0 grup` dan `Duplikat dalam split: 0 grup`. Laporan lengkap tersimpan di `backend/dataset/leak_report.txt`.

```
backend/dataset/
├── train/ (combination, dry, normal, oily)
├── val/   (combination, dry, normal, oily)
└── test/  (combination, dry, normal, oily)
```

### Langkah 3: Jalankan Training

```bash
python ml_training/train.py
```

Opsional, atur durasi training:

```bash
# Eksperimen cepat
python ml_training/train.py --epochs-phase1 5 --epochs-phase2 3

# Lebih lama / akurasi lebih baik
python ml_training/train.py --epochs-phase1 15 --epochs-phase2 10

# Coba backbone EfficientNetB0 ke folder terpisah agar mudah dibandingkan
python ml_training/train.py --backbone efficientnetb0 --output-dir app/ml_effnetb0
```

Bandingkan hasil kedua model lalu salin model terbaik ke `app/ml` (`skin_model.keras`,
`class_names.json`, `model_meta.json`, `calibration.json`).

Model akhir disimpan ke:
- `backend/app/ml/skin_model.keras`
- `backend/app/ml/class_names.json`
- `backend/app/ml/model_meta.json` (backbone, preprocessing, versi aturan)
- `backend/app/ml/calibration.json` (temperature scaling + ECE)
- laporan evaluasi (`evaluation_report_*.txt`) & ringkasan training (`training_summary_*.json`)

### Langkah 4: Atur Aturan Kombinasi

Dengan model 4 kelas, `combination` diprediksi langsung (rule-v3) sehingga bagian ini **opsional**. `COMBINATION_SCORE_THRESHOLD` hanya dipakai saat memuat model lama 3 kelas (rule-v2).

Di `backend/.env`:

```env
# Hanya untuk model lama 3 kelas (rule-v2):
# combination_score = 2 * min(P(dry), P(oily))
# is_combination = true jika skor >= ambang di bawah (0.50 = kedua kelas minimal 25%)
COMBINATION_SCORE_THRESHOLD=0.50

# Parameter lama (rule-v1) TIDAK dipakai lagi, dipertahankan agar .env lama tidak error
COMBINATION_THRESHOLD=0.10
COMBINATION_MIN_PAIR=0.50
```

Contoh model 4 kelas: `combination=61%`, `oily=20%`, `normal=14%`, `dry=5%` → `skin_type = combination`, `confidence = 61%`, `is_combination = true`.

### Langkah 5: Restart Backend

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Cek `http://localhost:8000/api/v1/health` — pastikan `model_loaded: true` dan `demo_mode: false`.
Untuk melihat backbone, aturan kombinasi aktif, temperature, dan ringkasan evaluasi terakhir, buka `http://localhost:8000/api/v1/ml/info`.

### Langkah 6: Buat Laporan Evaluasi (Opsional)

```bash
python ml_training/make_report.py --model-dir app/ml --compare-dir app/ml_effnetb0 --out ../docs/MODEL_REPORT.md
```

Laporan Markdown (model card, confusion matrix, status target, perbandingan model)
ditulis ke `docs/MODEL_REPORT.md`. Jalankan ulang setiap selesai training.

---

## 📱 FASE 3: Setup & Menjalankan Flutter App

### Prasyarat
- **Flutter SDK** (versi >= 3.13.2)
- **Android Studio** atau **VS Code** dengan ekstensi Flutter & Dart
- Perangkat Android fisik atau Android Emulator

---

### Langkah 1: Install Dependensi Flutter

Buka terminal baru, arahkan ke folder `mobile`:

```bash
cd mobile
flutter pub get
```

---

### Langkah 2: Jalankan Unit & Widget Test

Untuk memverifikasi integrasi kode, tema warna, dan pemodelan data:

```bash
flutter test
```

---

### Langkah 3: Menjalankan Aplikasi

#### A. Pada Emulator Android

Android Emulator memetakan `localhost` komputer host ke alamat IP khusus `10.0.2.2`. Jalankan dengan perintah:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

#### B. Pada HP Android Fisik (Tanpa Kabel, Wi-Fi Sama)

Ringkasnya: backend jalan di `0.0.0.0:8000`, HP membuka `http://<IP-PC>:8000`,
lalu aplikasi di-build dengan `--dart-define=API_BASE_URL=http://<IP-PC>:8000`.

1. Jalankan backend dengan host `0.0.0.0` (lihat Fase 1 Langkah 7) dan biarkan
   jendela terminalnya tetap terbuka.
2. Pastikan HP dan PC terhubung ke **Wi-Fi/hotspot yang sama**.
3. Cek **IPv4 Address** PC dengan `ipconfig` (mis. `192.168.1.15`).
4. Izinkan port `8000` di Windows Firewall (centang *Private networks* saat
   popup muncul, atau buat inbound rule TCP 8000).
5. Tes dari browser HP: `http://192.168.1.15:8000/api/v1/health` harus
   mengembalikan JSON `{"status":"ok", ...}`.
6. Jalankan aplikasi tanpa kabel, pilih salah satu:
   - **Wireless debugging** (Android 11+, mendukung hot reload):
     `adb pair <IP-HP>:<port-pairing> <kode>` → `adb connect <IP-HP>:<port>`,
     lalu `flutter run --dart-define=API_BASE_URL=http://192.168.1.15:8000`.
   - **Build APK lalu kirim ke HP** (tanpa adb):
     `flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.15:8000`
     lalu kirim `mobile/build/app/outputs/flutter-apk/app-release.apk` ke HP
     (Google Drive/WhatsApp/`python -m http.server`) dan install.

> Panduan langkah demi langkah lengkap, termasuk troubleshooting per gejala,
> ada di **[`mobile/README.md`](mobile/README.md)**.

> IP PC bisa berubah setiap konek ulang. Kalau aplikasi timeout, cek `ipconfig`
> dan build/run ulang dengan IP baru — `API_BASE_URL` di-*compile* saat build.

#### D. Pada Chrome (Web, untuk demo cepat)

Aplikasi juga bisa dijalankan langsung di browser tanpa emulator. Backend harus tetap berjalan di port `8000`:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Saat memilih foto, browser akan membuka dialog file (atau kamera jika didukung).

---

## 🚀 Panduan Push ke GitHub

Sebelum mengunggah kode ke GitHub, ikuti langkah-langkah berikut:

```bash
# 1. Pastikan berada di root folder proyek (skinly/)
cd "c:\Pemograman Mobile\Skinly"

# 2. Inisialisasi repository git (jika belum dilakukan)
git init

# 3. Tambahkan seluruh file proyek (file .env & cache sudah otomatis terabaikan via .gitignore)
git add .

# 4. Buat commit pertama
git commit -m "feat: initial commit - skinly app with fastapi backend and flutter mobile"

# 5. Ubah branch utama menjadi main
git branch -M main

# 6. Hubungkan dengan repository GitHub milik Anda
git remote add origin https://github.com/USERNAME_KAMU/NAMA_REPO_KAMU.git

# 7. Push kode ke GitHub
git push -u origin main
```

---

## 🔧 Panduan Troubleshooting

### 1. Konflik Port MySQL 3306 (Port already in use)
Jika port 3306 sudah terpakai oleh layanan MySQL lain atau bentrok antara Laragon dan XAMPP:
- **Opsi A**: Matikan salah satu server (gunakan salah satu: hanya Laragon atau hanya XAMPP).
- **Opsi B**: Ubah port MySQL di `my.ini` XAMPP ke port `3307`, lalu perbarui nilai `DB_PORT=3307` di file `backend/.env`.

### 2. Gagal Terhubung ke Backend dari HP Fisik (`Connection refused` / `Timeout`)
- Pastikan HP dan laptop berada dalam satu koneksi Wi-Fi yang sama (tidak menggunakan mode isolasi AP).
- Pastikan firewall Windows mengizinkan koneksi port 8000:
  - Buka *Windows Defender Firewall* -> *Inbound Rules* -> izinkan port 8000 TCP.
- Pastikan saat menjalankan backend uvicorn menggunakan `--host 0.0.0.0` (bukan `127.0.0.1`).

### 3. Error "Access denied for user 'root'@'localhost'"
- Cek password MySQL di file `.env`. Untuk instalasi default Laragon dan XAMPP, password biasanya kosong (`DB_PASSWORD=`).

---

## 🔐 Keamanan & Privasi

- **Penyimpanan Kredensial**: Token autentikasi JWT disimpan terenkripsi di penyimpanan aman sistem operasi (*EncryptedSharedPreferences* pada Android dan *Keychain* pada iOS) menggunakan pustaka `flutter_secure_storage`.
- **Enkripsi Kata Sandi**: Kata sandi pengguna dienkripsi secara satu arah (*one-way salted hash*) menggunakan algoritma `bcrypt` di sisi backend.
- **Isolasi Kepemilikan Data**: Seluruh data riwayat pemindaian dan umpan balik pengguna diikat dengan `user_id` yang diverifikasi dari payload token JWT.
- **Perlindungan File Sensitif**: File `.env`, folder uploads foto pengguna, dataset besar, dan file model Keras telah didaftarkan dalam `.gitignore` sehingga tidak akan bocor ke publik saat di-push ke GitHub.

---

## ⚠️ Disclaimer Medis

> **Perhatian**: Hasil deteksi jenis kulit dan rekomendasi perawatan pada aplikasi Skinly dihasilkan oleh model kecerdasan buatan (*Machine Learning*) untuk tujuan **edukasi dan estimasi umum**, **BUKAN merupakan diagnosis medis profesional**. Apabila mengalami gangguan kulit akut atau alergi, disarankan untuk selalu berkonsultasi langsung dengan dokter spesialis dermatologi.

---

## 📄 Lisensi

Proyek ini dikembangkan untuk keperluan akademik dan edukasi. Gunakan dataset dan model sesuai dengan lisensi masing-masing penyedia.
