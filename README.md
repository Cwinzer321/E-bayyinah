# 🏫 SIMS E-BAYYINAH (Sistem Informasi Manajemen Sekolah)

Aplikasi Manajemen Sekolah Terpadu berbasis **Android (Flutter)** dengan basis data **Google Sheets & Google Apps Script (REST API)** yang ringan, hemat biaya, dan siap digunakan.

---

## 🌟 Fitur Utama (Sesuai Spesifikasi PRD v1.0.0)

### 1. 🔐 Multi-Role Access & Autentikasi (FR-01 & FR-02)
- Mendukung 4 peran pengguna dengan tampilan antarmuka dan hak akses yang disesuaikan secara otomatis:
  - **Admin / TU**: Kendali penuh sistem, angkatan, data siswa, verifikasi SPP, dan konfigurasi API.
  - **Guru / Ustadz**: Input nilai tugas, UTS, UAS, dan pencatatan presensi kelas.
  - **Siswa**: Kartu Tanda Siswa (KTS) digital dengan QR Code, akses e-Rapor, riwayat absensi, dan tagihan SPP.
  - **Alumni**: Pelacakan karier (*Tracer Study*) dan pengajuan legalisir digital ijazah/rapor.
- Sandi dienkripsi dengan standar **SHA-256** di Google Apps Script.

### 2. 📊 Dashboard & Manajemen Siswa per Angkatan (FR-03 s/d FR-06)
- **Statistik Real-Time**: Total siswa aktif, total alumni, total angkatan, dan persentase kehadiran harian.
- **Navigasi Angkatan**: Tampilan berurutan dari **Angkatan Pertama (Al-Fatih)** hingga angkatan terkini beserta Tahun Masuk dan Tahun Lulus.
- **Pencarian & Filter Cepat**: Filter multi-kategori berdasarkan Angkatan, Status (Aktif/Lulus/Keluar), serta nama siswa atau NIS.
- **Detail Biodata Lengkap**: Data demografi, orang tua/wali, nomor WhatsApp, alamat domisili, dan kartu identitas siswa digital.

### 3. 📲 Presensi & Kehadiran Digital (FR-07 & FR-08)
- Pindai QR Code siswa atau check-in presensi manual.
- Perlindungan konkurensi dengan **LockService** di Apps Script untuk mencegah tabrakan data saat jam sibuk masuk sekolah.
- Rekap persentase kehadiran bulanan dan semesteran (Hadir, Izin, Sakit, Alpa).

### 4. 📝 Akademik & e-Rapor PDF (FR-09 & FR-10)
- Input nilai fleksibel dengan pembobotan: Tugas (30%), UTS (30%), UAS (40%) serta konversi predikat otomatis (A, B, C, D).
- Cetak langsung dan unduh **e-Rapor berformat PDF resmi** lengkap dengan Kop Yayasan Al-Bayyinah, tabel capaian kompetensi, dan tanda tangan digital.

### 5. 💳 Keuangan & SPP (FR-11 & FR-12)
- Pencatatan status pembayaran SPP per bulan (Lunas, Belum Lunas, Menunggu Verifikasi) dalam format Rupiah.
- Unggah bukti transfer bank / QRIS yang otomatis tersimpan ke **Google Drive** folder `E-Bayyinah_Bukti_Transfer`.
- Panel verifikasi pembayaran oleh Admin TU.

### 6. 🎓 Tracer Study & Legalisir Alumni (FR-13 & FR-14)
- Formulir pembaruan status aktivitas lulusan (Kuliah di PTN/PTS, Bekerja Profesional, Wirausaha, Mencari Kerja).
- Pengajuan permohonan legalisir dokumen resmi (Ijazah, SKL, Transkrip e-Rapor) secara digital.

---

## 🏗️ Struktur Proyek

```text
E-bayyinah/
├── backend/
│   ├── Code.gs                    # Skrip Google Apps Script REST API Backend
│   └── SPREADSHEET_SETUP_GUIDE.md # Panduan langkah demi langkah integrasi Google Sheets
├── lib/
│   ├── core/
│   │   ├── constants/             # AppColors, ApiConstants
│   │   ├── theme/                 # Material 3 Light Theme
│   │   └── utils/                 # CurrencyFormatter, DateFormatter
│   ├── models/                    # UserModel, StudentModel, AngkatanModel, PresensiModel, NilaiModel, SPPModel, TracerModel
│   ├── providers/                 # AuthProvider, StudentProvider, PresensiProvider, SPPProvider, AcademicProvider
│   ├── screens/
│   │   ├── auth/                  # LoginScreen dengan Preset Role Cepat
│   │   ├── dashboard/             # Admin, Guru, Siswa, dan Alumni Dashboard Tabs
│   │   ├── students/              # StudentListScreen, StudentDetailScreen, StudentFormScreen
│   │   ├── angkatan/              # AngkatanManageScreen
│   │   ├── presensi/              # PresensiScreen
│   │   ├── nilai/                 # NilaiScreen (Input & Export e-Rapor PDF)
│   │   ├── spp/                   # SPPScreen (Tagihan & Verifikasi)
│   │   ├── tracer/                # TracerScreen (Tracer Study & Legalisir)
│   │   └── settings/              # SettingsScreen (Konfigurasi URL Google Apps Script)
│   ├── services/                  # ApiService, AuthService, PdfReportService
│   ├── widgets/                   # QrCodeWidget (High performance pure-Dart QR)
│   └── main.dart                  # Root Application
└── pubspec.yaml
```

---

## 🔑 Akun Demo Pengujian Cepat

Aplikasi telah dilengkapi tombol **Preset Demo** di layar masuk untuk pengujian langsung:

| Role | Username / NIS | Password | Nama Akun |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin` | `admin123` | Admin TU Al-Bayyinah |
| **Guru** | `guru01` | `guru123` | Ust. Ahmad Dahlan, S.Pd.I |
| **Siswa** | `2024001` | `siswa123` | Muhammad Raihan (Angkatan 4) |
| **Alumni** | `2021001` | `alumni123` | Fajar Ramadhan (Angkatan 1) |

---

## 🚀 Cara Menjalankan Aplikasi

1. Pastikan Flutter SDK telah terpasang:
   ```bash
   flutter --version
   ```
2. Jalankan dependensi:
   ```bash
   flutter pub get
   ```
3. Jalankan aplikasi di emulator atau perangkat fisik Android:
   ```bash
   flutter run
   ```

---

## 🌐 Menghubungkan ke Google Sheets Anda Sendiri

Lihat panduan lengkap di [SPREADSHEET_SETUP_GUIDE.md](file:///c:/laragon/www/E-bayyinah/backend/SPREADSHEET_SETUP_GUIDE.md).
Cukup salin file [Code.gs](file:///c:/laragon/www/E-bayyinah/backend/Code.gs) ke Google Apps Script Spreadsheet Anda, jalankan `initializeDatabase()`, lalu deploy sebagai Web App!
