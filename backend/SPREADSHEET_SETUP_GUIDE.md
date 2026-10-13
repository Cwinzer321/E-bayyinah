# 📚 Panduan Integrasi Google Sheets & Google Apps Script (Backend SIMS E-Bayyinah)

Dokumen ini menjelaskan langkah-langkah menyiapkan Google Sheets sebagai database cloud tanpa biaya server (*serverless*) untuk aplikasi **E-Bayyinah SIMS**.

---

## 🚀 Langkah 1: Buat Spreadsheet Baru

1. Buka browser dan login ke akun Google Anda.
2. Akses [Google Sheets](https://sheets.new) untuk membuat spreadsheet baru.
3. Beri nama Spreadsheet, misalnya: `SIMS E-Bayyinah Database`.

---

## 🛠️ Langkah 2: Buka Apps Script & Salin Kode

1. Di menu atas Spreadsheet, klik **Ekstensi** > **Apps Script** (*Extensions* > *Apps Script*).
2. Hapus semua teks yang ada di editor file `Code.gs`.
3. Buka file [Code.gs](file:///c:/laragon/www/E-bayyinah/backend/Code.gs) di proyek ini, lalu salin (**Copy**) dan tempel (**Paste**) seluruh isinya ke editor Apps Script.
4. Klik tombol **Simpan** (ikon disket 💾) atau tekan `Ctrl + S`.

---

## ⚡ Langkah 3: Inisialisasi Database (Auto-Setup)

Anda tidak perlu membuat tab sheet secara manual satu per satu:
1. Di bilah toolbar atas Apps Script, temukan dropdown fungsi (di sebelah tombol *Debug*).
2. Pilih fungsi `initializeDatabase`.
3. Klik tombol **Jalankan** (*Run*).
4. Google akan meminta izin otorisasi pertama kali:
   - Klik **Tinjau Izin** (*Review permissions*)
   - Pilih akun Google Anda
   - Klik **Lanjutan** (*Advanced*) di bagian bawah
   - Klik **Buka Untitled project (tidak aman)** / *Go to project (unsafe)*
   - Klik **Izinkan** (*Allow*)
5. Buka kembali tab Spreadsheet Anda. Anda akan melihat 7 sheet baru telah dibuat otomatis beserta data contoh:
   - `Users`
   - `Master_Angkatan`
   - `Data_Siswa`
   - `Presensi`
   - `Nilai`
   - `SPP`
   - `Tracer_Alumni`

---

## 🌐 Langkah 4: Terapkan Sebagai Web App (Deploy REST API)

Agar aplikasi Android Flutter dapat mengakses data:
1. Di halaman Apps Script, klik tombol biru **Terapkan** (*Deploy*) di pojok kanan atas > pilih **Penerapan Baru** (*New deployment*).
2. Klik ikon gerigi ⚙️ di samping "Pilih jenis", lalu pilih **Aplikasi Web** (*Web app*).
3. Isi konfigurasi sebagai berikut:
   - **Deskripsi**: `SIMS E-Bayyinah API v1`
   - **Jalankan sebagai** (*Execute as*): **Saya (email@gmail.com)**
   - **Siapa yang memiliki akses** (*Who has access*): **Siapa saja** (*Anyone*) ⚠️ *Wajib dipilih "Anyone" agar aplikasi Android dapat mengirim request tanpa perlu login OAuth Google*.
4. Klik **Terapkan** (*Deploy*).
5. Salin **URL Aplikasi Web** (*Web App URL*) yang dihasilkan (formatnya: `https://script.google.com/macros/s/.../exec`).

---

## 📱 Langkah 5: Masukkan URL ke Aplikasi Android

Buka file konfigurasi di aplikasi Flutter:
`lib/core/constants/api_constants.dart`

Ganti nilai `baseUrl` dengan URL yang Anda salin:

```dart
class ApiConstants {
  static const String baseUrl = 'https://script.google.com/macros/s/AKfycbx.../exec';
}
```

---

## 🔑 Akun Demo Bawaan (Default Accounts)

Setelah inisialisasi, akun default berikut langsung aktif:

| Role | Username / NIS | Password | Keterangan |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin` | `admin123` | Akses penuh (TU, Siswa, Angkatan, Verifikasi SPP) |
| **Guru** | `guru01` | `guru123` | Input Nilai, Rekap Presensi |
| **Siswa** | `2024001` | `siswa123` | Muhammad Raihan (Angkatan 4) - Biodata, Jadwal, SPP, e-Rapor |
| **Alumni** | `2021001` | `alumni123` | Fajar Ramadhan (Angkatan 1) - Tracer Study & Legalisir |

---

## 🧪 Uji Coba Endpoint di Browser

Anda dapat menguji apakah API berjalan dengan membuka URL Web App di browser:
- `https://script.google.com/macros/s/.../exec?action=ping`
  - Output: `{"success":true,"message":"E-Bayyinah API Server Online"}`
- `https://script.google.com/macros/s/.../exec?action=get_dashboard_stats`
- `https://script.google.com/macros/s/.../exec?action=get_angkatan_list`
