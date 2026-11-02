-- ============================================================
-- Skinly - Setup Database MySQL/MariaDB
-- Jalankan file ini lewat HeidiSQL, phpMyAdmin, atau MySQL CLI:
--   mysql -u root -p < create_database.sql
-- ============================================================

-- Buat database utama
CREATE DATABASE IF NOT EXISTS `skinly`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Buat database untuk pengujian (terpisah dari data asli)
CREATE DATABASE IF NOT EXISTS `skinly_test`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Verifikasi
SHOW DATABASES LIKE 'skinly%';
