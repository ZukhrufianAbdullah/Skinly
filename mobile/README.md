# Menjalankan Skinly di HP (Tanpa Kabel)

Panduan ini menjelaskan cara menjalankan aplikasi Flutter Skinly di HP Android
yang terhubung ke **jaringan Wi-Fi yang sama** dengan laptop/PC tempat backend
berjalan — tanpa kabel USB sama sekali.

> Ringkasan alur:
> backend di PC (`0.0.0.0:8000`) → HP mengakses `http://<IP-PC>:8000` →
> aplikasi di-build dengan `--dart-define=API_BASE_URL=http://<IP-PC>:8000`.

---

## 1. Jalankan backend di PC

Buka PowerShell, lalu:

```powershell
cd C:\Users\Lenovo\StudioProjects\Skinly\backend
& "C:\Users\Lenovo\anaconda3\envs\skinly\python.exe" -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Jangan tutup jendela PowerShell ini selama aplikasi dipakai.

Cek di browser PC: <http://localhost:8000/api/v1/health>
Harus muncul `"model_loaded": true` dan `"demo_mode": false`.

> `--host 0.0.0.0` **wajib**. Kalau hanya `127.0.0.1`, HP tidak bisa mengakses
> backend meskipun satu Wi-Fi.

---

## 2. Cari IP LAN PC

```powershell
ipconfig
```

Lihat adapter yang sedang dipakai (Wi-Fi / hotspot), catat **IPv4 Address**-nya.
Contoh: `192.168.1.10` atau `192.168.43.25`.

Contoh hasil:

```
Wireless LAN adapter Wi-Fi:
   IPv4 Address. . . . . . . . . . . : 192.168.1.10
```

Di panduan ini, ganti `<IP-PC>` dengan angka tersebut.

> IP bisa berubah setiap kali konek ulang. Kalau aplikasi tiba-tiba timeout,
> cek ulang IP lalu build ulang dengan IP baru.

---

## 3. Izinkan port 8000 di Windows Firewall

Paling mudah: saat backend pertama kali dijalankan, muncul popup
**Windows Defender Firewall** → centang **Private networks** → **Allow access**.

Kalau popup tidak muncul atau dulu pernah ditolak, buka PowerShell **sebagai
Administrator** dan jalankan:

```powershell
New-NetFirewallRule -DisplayName "Skinly Backend 8000" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
```

---

## 4. Tes koneksi dari HP (sebelum build aplikasi)

1. Pastikan HP dan PC terhubung ke **Wi-Fi/hotspot yang sama**.
2. Buka browser di HP, akses:

   ```
   http://<IP-PC>:8000/api/v1/health
   ```

3. Kalau muncul JSON `{"status":"ok", ...}` → koneksi siap.
   Kalau `ERR_CONNECTION_TIMED_OUT` / tidak bisa dibuka:
   - Pastikan backend masih berjalan.
   - Pastikan `--host 0.0.0.0`.
   - Cek firewall (langkah 3).
   - Jaringan kampus/kantor kadang memakai *client isolation*; gunakan
     hotspot HP (lihat bagian Troubleshooting).

---

## 5A. Jalankan langsung via Wireless Debugging (Android 11+)

Cara ini tidak perlu kabel dan mendukung hot reload.

### Aktifkan Wireless Debugging di HP

1. **Settings → About phone** → ketuk **Build number** 7× untuk membuka
   Developer options.
2. **Settings → System → Developer options** → aktifkan
   **Wireless debugging**.
3. Ketuk **Wireless debugging** → **Pair device with pairing code**.
   Muncul **IP address & port pairing** + **6-digit code**.

### Pair dari PC

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

# Ganti angka sesuai yang tampil di HP
& $adb pair 192.168.1.20:37123 123456
```

Lalu sambungkan (port berbeda dari port pairing — lihat layar Wireless
debugging utama):

```powershell
& $adb connect 192.168.1.20:40001
& $adb devices
```

`adb devices` harus menampilkan perangkat dengan status `device`.

### Jalankan aplikasi

```powershell
cd C:\Users\Lenovo\StudioProjects\Skinly\mobile
flutter run --dart-define=API_BASE_URL=http://<IP-PC>:8000
```

Kalau ada lebih dari satu device, pilih dengan `-d`:

```powershell
flutter devices
flutter run -d <device-id> --dart-define=API_BASE_URL=http://<IP-PC>:8000
```

---

## 5B. Build APK lalu kirim ke HP (tanpa kabel, tanpa adb)

Cocok kalau tidak ingin mengaktifkan developer options.

### Build APK release

```powershell
cd C:\Users\Lenovo\StudioProjects\Skinly\mobile
flutter build apk --release --dart-define=API_BASE_URL=http://<IP-PC>:8000
```

Hasil: `mobile\build\app\outputs\flutter-apk\app-release.apk`

### Kirim & pasang di HP

Pilih salah satu (tidak butuh kabel):

- Upload ke Google Drive → buka di HP → download → install.
- Kirim ke diri sendiri via WhatsApp/Telegram → download → install.
- `python -m http.server 8080` di folder APK, lalu buka
  `http://<IP-PC>:8080/app-release.apk` di browser HP.

Saat install, izinkan **Install unknown apps** untuk aplikasi sumbernya.

> APK hanya bisa mengakses backend dengan alamat yang di-*compile* saat build.
> Kalau IP PC berubah, build ulang APK dengan `--dart-define` yang baru.

---

## 6. Login uji

| Email | Password |
| --- | --- |
| `testuser@skinly.local` | `Test12345` |

Atau daftar akun baru langsung dari aplikasi.

---

## Troubleshooting

| Gejala | Penyebab & solusi |
| --- | --- |
| `Tidak dapat terhubung ke server` | HP dan PC beda jaringan, IP salah, backend mati, atau firewall memblokir port 8000. |
| Browser HP bisa buka `/health`, aplikasi tidak | `API_BASE_URL` tidak di-set saat build/run. Ulangi dengan `--dart-define`. |
| Timeout setelah ganti Wi-Fi | IP PC berubah. Cek `ipconfig`, build/run ulang. |
| `adb devices` kosong | Wireless debugging belum aktif, pairing gagal, atau port salah (port pairing ≠ port koneksi). |
| Jaringan kampus tidak bisa akses PC | Router memakai *client isolation*. Gunakan hotspot HP: nyalakan hotspot di HP, sambungkan Wi-Fi PC ke hotspot itu, lalu pakai IPv4 PC yang baru (`ipconfig`). |
| Install APK ditolak | Izinkan **Install unknown apps** untuk aplikasi pengirim file. |
| Kamera tidak muncul | Beri izin Kamera & Galeri saat aplikasi meminta. |
| Macet di splash, atau onboarding muncul lagi setiap aplikasi dibuka | Build release dengan R8 aktif me-rename kelas Kotlin yang dipakai plugin storage (`NoSuchMethodError ... SharedPreferencesApiRegistrar`), sehingga flag onboarding/token gagal disimpan. Pastikan `isMinifyEnabled = false` di `mobile/android/app/build.gradle.kts`, lalu `flutter clean` + build ulang. |
| Splash terasa lama (±6 detik) | Backend tidak terjangkau dari HP, jadi splash menunggu batas waktu lalu lanjut ke halaman login. Cek IP PC, backend, dan firewall. |

---

## Catatan untuk emulator

- Android Emulator: `API_BASE_URL` default sudah `http://10.0.2.2:8000`
  (tidak perlu `--dart-define`).
- Chrome/web: otomatis memakai `http://localhost:8000`.

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```
