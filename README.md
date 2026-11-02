# Skinly - Aplikasi Pendeteksi Jenis Kulit Wajah

Skinly adalah aplikasi mobile modern berbasis **Machine Learning** yang mendeteksi jenis kulit wajah (**Normal**, **Oily**, **Dry**, **Combination**) menggunakan model **MobileNetV2** dengan Transfer Learning. Proyek ini dilengkapi backend REST API berbasis **FastAPI** dan aplikasi mobile berbasis **Flutter**.

---

## 🌟 Fitur Utama

- **Deteksi 4 Jenis Kulit Wajah**: Analisis klasifikasi citra wajah (*Normal, Oily, Dry, Combination*) lengkap dengan nilai akurasi (*confidence score*) dan distribusi probabilitas seluruh tipe kulit.
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
    │   │   └── v1/          # Endpoints: auth, scans, articles, feedback, health
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

## 🤖 FASE 2: Pelatihan Model Machine Learning (Opsional)

Jika ingin melatih ulang model deteksi kulit menggunakan dataset kustom:
1. Baca panduan lengkap di [backend/ml_training/README.md](backend/ml_training/README.md).
2. Siapkan dataset wajah dengan struktur folder:
   ```
   backend/dataset/
   ├── train/ (normal, oily, dry, combination)
   ├── val/   (normal, oily, dry, combination)
   └── test/  (normal, oily, dry, combination)
   ```
3. Jalankan script pelatihan:
   ```bash
   cd backend
   python ml_training/train.py
   ```
4. Model terlatih akan disimpan ke `backend/app/ml/skin_model.keras`.
5. Restart server uvicorn backend untuk memuat model baru secara otomatis.

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

#### B. Pada HP Android Fisik

1. Sambungkan HP ke laptop/PC menggunakan kabel data USB.
2. Aktifkan **Developer Options** (*Opsi Pengembang*) dan **USB Debugging** di pengaturan HP.
3. Pastikan HP dan laptop terhubung ke **jaringan Wi-Fi yang SAMA**.
4. Cek alamat IP lokal laptop:
   - Windows: buka CMD / PowerShell, ketik `ipconfig`, lalu catat alamat **IPv4 Address** (misalnya `192.168.1.15`).
5. Jalankan aplikasi dengan mengarahkan `API_BASE_URL` ke IP tersebut:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.15:8000
```

#### C. Build APK Release (Instalasi Manual)

Untuk menghasilkan file APK siap pasang di perangkat Android:

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://IP_SERVER_KAMU:8000
```
File APK akan berada di `mobile/build/app/outputs/flutter-apk/app-release.apk`.

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
