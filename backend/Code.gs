/**
 * ==========================================================================
 * SISTEM INFORMASI MANAJEMEN SEKOLAH (SIMS) - E-BAYYINAH
 * Google Apps Script REST API Backend
 * Versi: 1.0.0
 * 
 * Fitur:
 * - Multi-Role Authentication (Admin, Guru, Siswa, Alumni) dengan SHA-256
 * - Manajemen Angkatan & Siswa Terintegrasi (Angkatan 1 dst)
 * - Presensi QR & Manual dengan Concurrency Lock (LockService)
 * - Penilaian & e-Rapor
 * - Keuangan & SPP (Upload Bukti Bayar Base64 ke Google Drive)
 * - Tracer Study & Permohonan Legalisir Digital Alumni
 * - Auto-Initialization Database & Data Dummy Realistis
 * ==========================================================================
 */

const SPREADSHEET_ID = ""; // Kosongkan jika script terikat pada Spreadsheet aktif (Container-bound)

function getSpreadsheet() {
  if (SPREADSHEET_ID && SPREADSHEET_ID.trim() !== "") {
    return SpreadsheetApp.openById(SPREADSHEET_ID);
  }
  return SpreadsheetApp.getActiveSpreadsheet();
}

/**
 * Handle HTTP GET Requests
 */
function doGet(e) {
  try {
    const action = e.parameter.action || "ping";
    let result = {};

    switch (action) {
      case "ping":
        result = { success: true, message: "E-Bayyinah API Server Online", timestamp: new Date().toISOString() };
        break;

      case "init_database":
        result = initializeDatabase();
        break;

      case "login":
        result = handleLogin(e.parameter.username, e.parameter.password);
        break;

      case "get_dashboard_stats":
        result = getDashboardStats();
        break;

      case "get_angkatan_list":
        result = getAngkatanList();
        break;

      case "get_students":
        result = getStudents(
          e.parameter.id_angkatan,
          e.parameter.search,
          e.parameter.status
        );
        break;

      case "get_student_detail":
        result = getStudentDetail(e.parameter.id_siswa);
        break;

      case "get_presensi_history":
        result = getPresensiHistory(
          e.parameter.id_siswa,
          e.parameter.bulan,
          e.parameter.tanggal
        );
        break;

      case "get_nilai_list":
        result = getNilaiList(
          e.parameter.id_siswa,
          e.parameter.semester,
          e.parameter.tahun_ajaran
        );
        break;

      case "get_spp_list":
        result = getSPPList(
          e.parameter.id_siswa,
          e.parameter.tahun,
          e.parameter.status_bayar
        );
        break;

      case "get_tracer_list":
        result = getTracerList(
          e.parameter.tahun_lulus,
          e.parameter.search
        );
        break;

      case "get_alumni_profile":
        result = getAlumniProfile(e.parameter.id_siswa);
        break;

      default:
        result = { success: false, message: "Action GET '" + action + "' tidak dikenali" };
    }

    return buildJsonResponse(result);
  } catch (err) {
    return buildJsonResponse({ success: false, message: "Server Error: " + err.toString() });
  }
}

/**
 * Handle HTTP POST Requests
 */
function doPost(e) {
  const lock = LockService.getScriptLock();
  try {
    // Tunggu antrian write hingga 15 detik untuk mencegah race-condition
    lock.waitLock(15000);

    let data = {};
    if (e.postData && e.postData.contents) {
      data = JSON.parse(e.postData.contents);
    } else {
      data = e.parameter;
    }

    const action = data.action || "";
    let result = {};

    switch (action) {
      case "init_database":
        result = initializeDatabase();
        break;

      case "login":
        result = handleLogin(data.username, data.password);
        break;

      case "save_angkatan":
        result = saveAngkatan(data.payload);
        break;

      case "save_student":
        result = saveStudent(data.payload);
        break;

      case "delete_student":
        result = deleteStudent(data.id_siswa);
        break;

      case "record_presensi":
        result = recordPresensi(data.payload);
        break;

      case "save_nilai":
        result = saveNilai(data.payload);
        break;

      case "pay_spp":
        result = paySPP(data.payload);
        break;

      case "verify_spp":
        result = verifySPP(data.id_spp, data.status, data.verified_by);
        break;

      case "update_tracer":
        result = updateTracer(data.payload);
        break;

      case "request_legalisir":
        result = requestLegalisir(data.payload);
        break;

      default:
        result = { success: false, message: "Action POST '" + action + "' tidak dikenali" };
    }

    return buildJsonResponse(result);
  } catch (err) {
    return buildJsonResponse({ success: false, message: "Error Eksekusi POST: " + err.toString() });
  } finally {
    lock.releaseLock();
  }
}

/**
 * Utilitas Response JSON
 */
function buildJsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

/**
 * Utilitas Hashing Sandi (SHA-256)
 */
function hashPassword(password) {
  const rawHash = Utilities.computeDigest(
    Utilities.DigestAlgorithm.SHA_256,
    password,
    Utilities.Charset.UTF_8
  );
  let hex = "";
  for (let i = 0; i < rawHash.length; i++) {
    let byteVal = rawHash[i];
    if (byteVal < 0) byteVal += 256;
    let byteStr = byteVal.toString(16);
    if (byteStr.length == 1) byteStr = "0" + byteStr;
    hex += byteStr;
  }
  return hex;
}

/**
 * Autentikasi Pengguna Multi-Role
 */
function handleLogin(username, password) {
  if (!username || !password) {
    return { success: false, message: "Username dan Kata Sandi wajib diisi" };
  }

  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Users");
  if (!sheet) {
    return { success: false, message: "Tabel Users belum dibuat. Jalankan init_database terlebih dahulu." };
  }

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) {
    return { success: false, message: "Belum ada akun terdaftar" };
  }

  const inputHash = hashPassword(password);
  const headers = data[0];
  const idxUser = headers.indexOf("Username");
  const idxPass = headers.indexOf("Password_Hash");
  const idxRole = headers.indexOf("Role");
  const idxRef = headers.indexOf("ID_Ref");
  const idxName = headers.indexOf("Full_Name");
  const idxStatus = headers.indexOf("Status");

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    if (String(row[idxUser]).trim().toLowerCase() === String(username).trim().toLowerCase()) {
      if (String(row[idxPass]) === inputHash || String(row[idxPass]) === password) { // kompatibilitas hash atau plain pertama
        if (String(row[idxStatus]).toLowerCase() !== "aktif") {
          return { success: false, message: "Akun Anda berstatus non-aktif. Hubungi Admin TU." };
        }

        // Ambil profil siswa jika role siswa / alumni
        let studentProfile = null;
        if (row[idxRef]) {
          studentProfile = getStudentDetail(row[idxRef]).data;
        }

        return {
          success: true,
          message: "Login berhasil",
          user: {
            id_user: row[headers.indexOf("ID_User")],
            username: row[idxUser],
            role: row[idxRole],
            id_ref: row[idxRef],
            full_name: row[idxName],
            student_profile: studentProfile
          }
        };
      } else {
        return { success: false, message: "Kata sandi salah" };
      }
    }
  }

  return { success: false, message: "Pengguna tidak ditemukan" };
}

/**
 * Dashboard & Statistik Utama
 */
function getDashboardStats() {
  const ss = getSpreadsheet();
  const sheetSiswa = ss.getSheetByName("Data_Siswa");
  const sheetAngkatan = ss.getSheetByName("Master_Angkatan");
  const sheetSPP = ss.getSheetByName("SPP");
  const sheetPresensi = ss.getSheetByName("Presensi");

  let totalSiswaAktif = 0;
  let totalAlumni = 0;
  let totalAngkatan = 0;
  let sppLunasBulanIni = 0;
  let sppTertunggakBulanIni = 0;
  let kehadiranHariIni = 0;

  if (sheetAngkatan && sheetAngkatan.getLastRow() > 1) {
    totalAngkatan = sheetAngkatan.getLastRow() - 1;
  }

  if (sheetSiswa && sheetSiswa.getLastRow() > 1) {
    const rows = sheetSiswa.getDataRange().getValues();
    const idxStatus = rows[0].indexOf("Status");
    for (let i = 1; i < rows.length; i++) {
      const st = String(rows[i][idxStatus]).toLowerCase();
      if (st === "aktif") totalSiswaAktif++;
      else if (st === "lulus" || st === "alumni") totalAlumni++;
    }
  }

  const todayStr = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd");
  if (sheetPresensi && sheetPresensi.getLastRow() > 1) {
    const pRows = sheetPresensi.getDataRange().getValues();
    const idxTgl = pRows[0].indexOf("Tanggal");
    const idxSt = pRows[0].indexOf("Status_Hadir");
    for (let i = 1; i < pRows.length; i++) {
      let tgl = pRows[i][idxTgl];
      if (tgl instanceof Date) {
        tgl = Utilities.formatDate(tgl, Session.getScriptTimeZone(), "yyyy-MM-dd");
      }
      if (String(tgl) === todayStr && String(pRows[i][idxSt]).toLowerCase() === "hadir") {
        kehadiranHariIni++;
      }
    }
  }

  return {
    success: true,
    data: {
      total_siswa_aktif: totalSiswaAktif,
      total_alumni: totalAlumni,
      total_angkatan: totalAngkatan,
      kehadiran_hari_ini: kehadiranHariIni,
      persentase_kehadiran: totalSiswaAktif > 0 ? Math.round((kehadiranHariIni / totalSiswaAktif) * 100) : 0
    }
  };
}

/**
 * Manajemen Angkatan
 */
function getAngkatanList() {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Master_Angkatan");
  if (!sheet || sheet.getLastRow() <= 1) return { success: true, data: [] };

  const rows = sheet.getDataRange().getValues();
  const headers = rows[0];
  const list = [];

  for (let i = 1; i < rows.length; i++) {
    const obj = {};
    headers.forEach((h, idx) => obj[h.toLowerCase()] = rows[i][idx]);
    list.push(obj);
  }

  return { success: true, data: list };
}

function saveAngkatan(payload) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Master_Angkatan");
  const headers = sheet.getDataRange().getValues()[0];

  const idAngkatan = payload.id_angkatan || ("ANGK-" + (sheet.getLastRow()));
  const data = sheet.getDataRange().getValues();
  let foundRow = -1;

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][headers.indexOf("ID_Angkatan")]) === String(idAngkatan)) {
      foundRow = i + 1;
      break;
    }
  }

  const rowData = [
    idAngkatan,
    payload.nama_angkatan || "",
    payload.tahun_masuk || new Date().getFullYear(),
    payload.tahun_lulus || (Number(payload.tahun_masuk || new Date().getFullYear()) + 3),
    payload.total_siswa || 0,
    payload.status || "Aktif",
    payload.keterangan || ""
  ];

  if (foundRow > 0) {
    sheet.getRange(foundRow, 1, 1, rowData.length).setValues([rowData]);
  } else {
    sheet.appendRow(rowData);
  }

  return { success: true, message: "Data Angkatan berhasil disimpan", id_angkatan: idAngkatan };
}

/**
 * Manajemen Data Siswa
 */
function getStudents(idAngkatan, search, status) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Data_Siswa");
  if (!sheet || sheet.getLastRow() <= 1) return { success: true, data: [] };

  const rows = sheet.getDataRange().getValues();
  const headers = rows[0];
  const idxId = headers.indexOf("ID_Siswa");
  const idxNis = headers.indexOf("NIS");
  const idxNama = headers.indexOf("Nama_Lengkap");
  const idxAngk = headers.indexOf("ID_Angkatan");
  const idxStatus = headers.indexOf("Status");

  let list = [];

  for (let i = 1; i < rows.length; i++) {
    const r = rows[i];
    
    // Filter Angkatan
    if (idAngkatan && idAngkatan !== "ALL" && String(r[idxAngk]) !== String(idAngkatan)) {
      continue;
    }

    // Filter Status
    if (status && status !== "ALL" && String(r[idxStatus]).toLowerCase() !== String(status).toLowerCase()) {
      continue;
    }

    // Filter Search
    if (search) {
      const q = String(search).toLowerCase();
      const matchNis = String(r[idxNis]).toLowerCase().includes(q);
      const matchNama = String(r[idxNama]).toLowerCase().includes(q);
      if (!matchNis && !matchNama) continue;
    }

    const obj = {};
    headers.forEach((h, idx) => {
      let val = r[idx];
      if (val instanceof Date) {
        val = Utilities.formatDate(val, Session.getScriptTimeZone(), "yyyy-MM-dd");
      }
      obj[h.toLowerCase()] = val;
    });
    list.push(obj);
  }

  return { success: true, data: list, count: list.length };
}

function getStudentDetail(idSiswa) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Data_Siswa");
  if (!sheet) return { success: false, message: "Sheet Data_Siswa tidak ditemukan" };

  const rows = sheet.getDataRange().getValues();
  const headers = rows[0];
  const idxId = headers.indexOf("ID_Siswa");

  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][idxId]) === String(idSiswa)) {
      const obj = {};
      headers.forEach((h, idx) => {
        let val = rows[i][idx];
        if (val instanceof Date) {
          val = Utilities.formatDate(val, Session.getScriptTimeZone(), "yyyy-MM-dd");
        }
        obj[h.toLowerCase()] = val;
      });
      return { success: true, data: obj };
    }
  }

  return { success: false, message: "Siswa dengan ID " + idSiswa + " tidak ditemukan" };
}

function saveStudent(p) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Data_Siswa");
  const headers = sheet.getDataRange().getValues()[0];

  const idSiswa = p.id_siswa || ("SISWA-" + Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyMMddHHmmss"));
  const data = sheet.getDataRange().getValues();
  let foundRow = -1;

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][headers.indexOf("ID_Siswa")]) === String(idSiswa)) {
      foundRow = i + 1;
      break;
    }
  }

  const rowData = [
    idSiswa,
    p.nis || "",
    p.nisn || "",
    p.nama_lengkap || "",
    p.id_angkatan || "",
    p.jenis_kelamin || "L",
    p.tempat_lahir || "",
    p.tgl_lahir || "",
    p.alamat || "",
    p.no_hp || "",
    p.nama_ortu || "",
    p.status || "Aktif"
  ];

  if (foundRow > 0) {
    sheet.getRange(foundRow, 1, 1, rowData.length).setValues([rowData]);
  } else {
    sheet.appendRow(rowData);
    // Buat akun otomatis di sheet Users jika belum ada
    createOrUpdateUserAccount(p.nis, p.nis, "Siswa", idSiswa, p.nama_lengkap);
  }

  return { success: true, message: "Data Siswa berhasil disimpan", id_siswa: idSiswa };
}

function deleteStudent(idSiswa) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Data_Siswa");
  const data = sheet.getDataRange().getValues();
  const idxId = data[0].indexOf("ID_Siswa");

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][idxId]) === String(idSiswa)) {
      sheet.deleteRow(i + 1);
      return { success: true, message: "Data siswa berhasil dihapus" };
    }
  }
  return { success: false, message: "Data siswa tidak ditemukan" };
}

/**
 * Utilitas Akun Pengguna
 */
function createOrUpdateUserAccount(username, defaultPass, role, idRef, fullName) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Users");
  if (!sheet) return;

  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idxUser = headers.indexOf("Username");

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][idxUser]) === String(username)) {
      return; // akun sudah ada
    }
  }

  const newId = "USR-" + (sheet.getLastRow());
  const passHash = hashPassword(defaultPass);
  sheet.appendRow([
    newId,
    username,
    passHash,
    role,
    idRef,
    fullName,
    "Aktif",
    new Date()
  ]);
}

/**
 * Presensi Siswa (Digital QR & GPS)
 */
function recordPresensi(p) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Presensi");
  if (!sheet) return { success: false, message: "Sheet Presensi tidak ditemukan" };

  const idPresensi = "PRS-" + Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyyMMdd-HHmmss-") + Math.floor(Math.random() * 900 + 100);
  const tanggal = p.tanggal || Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd");
  const jam = p.jam_scan || Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "HH:mm:ss");

  // Cek duplikasi absensi di tanggal yang sama untuk siswa tersebut
  const data = sheet.getDataRange().getValues();
  const idxTgl = data[0].indexOf("Tanggal");
  const idxIdSiswa = data[0].indexOf("ID_Siswa");

  for (let i = 1; i < data.length; i++) {
    let tglRow = data[i][idxTgl];
    if (tglRow instanceof Date) {
      tglRow = Utilities.formatDate(tglRow, Session.getScriptTimeZone(), "yyyy-MM-dd");
    }
    if (String(tglRow) === String(tanggal) && String(data[i][idxIdSiswa]) === String(p.id_siswa)) {
      return { success: false, message: "Siswa sudah tercatat hadir untuk tanggal " + tanggal };
    }
  }

  sheet.appendRow([
    idPresensi,
    tanggal,
    p.id_siswa,
    p.status_hadir || "Hadir",
    jam,
    p.metode || "QR Code",
    p.lokasi || "Sekolah Al-Bayyinah"
  ]);

  return { success: true, message: "Presensi berhasil dicatat", id_presensi: idPresensi, jam: jam };
}

function getPresensiHistory(idSiswa, bulan, tanggal) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Presensi");
  if (!sheet || sheet.getLastRow() <= 1) return { success: true, data: [] };

  const rows = sheet.getDataRange().getValues();
  const headers = rows[0];
  const idxIdSiswa = headers.indexOf("ID_Siswa");
  const idxTgl = headers.indexOf("Tanggal");
  const list = [];

  for (let i = 1; i < rows.length; i++) {
    const r = rows[i];
    if (idSiswa && String(r[idxIdSiswa]) !== String(idSiswa)) continue;

    let tglVal = r[idxTgl];
    let tglStr = "";
    if (tglVal instanceof Date) {
      tglStr = Utilities.formatDate(tglVal, Session.getScriptTimeZone(), "yyyy-MM-dd");
    } else {
      tglStr = String(tglVal);
    }

    if (tanggal && tglStr !== String(tanggal)) continue;
    if (bulan && !tglStr.startsWith(String(bulan))) continue;

    const obj = {};
    headers.forEach((h, idx) => {
      let v = r[idx];
      if (v instanceof Date) v = Utilities.formatDate(v, Session.getScriptTimeZone(), "yyyy-MM-dd");
      obj[h.toLowerCase()] = v;
    });
    list.push(obj);
  }

  return { success: true, data: list.reverse() };
}

/**
 * Nilai & e-Rapor
 */
function getNilaiList(idSiswa, semester, tahunAjaran) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Nilai");
  if (!sheet || sheet.getLastRow() <= 1) return { success: true, data: [] };

  const rows = sheet.getDataRange().getValues();
  const headers = rows[0];
  const idxIdSiswa = headers.indexOf("ID_Siswa");
  const idxSem = headers.indexOf("Semester");
  const idxThn = headers.indexOf("Tahun_Ajaran");
  const list = [];

  for (let i = 1; i < rows.length; i++) {
    const r = rows[i];
    if (idSiswa && String(r[idxIdSiswa]) !== String(idSiswa)) continue;
    if (semester && String(r[idxSem]) !== String(semester)) continue;
    if (tahunAjaran && String(r[idxThn]) !== String(tahunAjaran)) continue;

    const obj = {};
    headers.forEach((h, idx) => obj[h.toLowerCase()] = r[idx]);
    list.push(obj);
  }

  return { success: true, data: list };
}

function saveNilai(p) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Nilai");
  const headers = sheet.getDataRange().getValues()[0];

  const idNilai = p.id_nilai || ("NIL-" + Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyyMMdd-HHmmss"));
  const tugas = Number(p.tugas || 0);
  const uts = Number(p.uts || 0);
  const uas = Number(p.uas || 0);
  const nilaiAkhir = Math.round((tugas * 0.3) + (uts * 0.3) + (uas * 0.4));
  
  let predikat = "D";
  if (nilaiAkhir >= 90) predikat = "A";
  else if (nilaiAkhir >= 80) predikat = "B";
  else if (nilaiAkhir >= 70) predikat = "C";

  const rowData = [
    idNilai,
    p.id_siswa,
    p.semester || "Ganjil",
    p.tahun_ajaran || "2024/2025",
    p.mata_pelajaran || "Pendidikan Agama",
    tugas,
    uts,
    uas,
    nilaiAkhir,
    predikat
  ];

  sheet.appendRow(rowData);
  return { success: true, message: "Nilai berhasil disimpan", id_nilai: idNilai, nilai_akhir: nilaiAkhir, predikat: predikat };
}

/**
 * Keuangan & SPP
 */
function getSPPList(idSiswa, tahun, statusBayar) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("SPP");
  if (!sheet || sheet.getLastRow() <= 1) return { success: true, data: [] };

  const rows = sheet.getDataRange().getValues();
  const headers = rows[0];
  const idxIdSiswa = headers.indexOf("ID_Siswa");
  const idxThn = headers.indexOf("Tahun");
  const idxSt = headers.indexOf("Status_Bayar");
  const list = [];

  for (let i = 1; i < rows.length; i++) {
    const r = rows[i];
    if (idSiswa && String(r[idxIdSiswa]) !== String(idSiswa)) continue;
    if (tahun && String(r[idxThn]) !== String(tahun)) continue;
    if (statusBayar && String(r[idxSt]).toLowerCase() !== String(statusBayar).toLowerCase()) continue;

    const obj = {};
    headers.forEach((h, idx) => {
      let v = r[idx];
      if (v instanceof Date) v = Utilities.formatDate(v, Session.getScriptTimeZone(), "yyyy-MM-dd");
      obj[h.toLowerCase()] = v;
    });
    list.push(obj);
  }

  return { success: true, data: list };
}

function paySPP(p) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("SPP");
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idxId = headers.indexOf("ID_SPP");

  let driveFileUrl = "";
  // Simpan bukti transfer ke Google Drive jika ada file base64
  if (p.bukti_base64 && p.bukti_filename) {
    driveFileUrl = saveFileToDrive(p.bukti_base64, p.bukti_filename);
  }

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][idxId]) === String(p.id_spp)) {
      const rowNum = i + 1;
      sheet.getRange(rowNum, headers.indexOf("Nominal_Bayar") + 1).setValue(p.nominal_bayar || data[i][headers.indexOf("Nominal_Tagihan")]);
      sheet.getRange(rowNum, headers.indexOf("Tgl_Bayar") + 1).setValue(new Date());
      sheet.getRange(rowNum, headers.indexOf("Status_Bayar") + 1).setValue("Menunggu_Verifikasi");
      if (driveFileUrl) {
        sheet.getRange(rowNum, headers.indexOf("Bukti_Url") + 1).setValue(driveFileUrl);
      }
      return { success: true, message: "Pembayaran SPP terkirim, menunggu verifikasi Admin", bukti_url: driveFileUrl };
    }
  }

  return { success: false, message: "Tagihan SPP tidak ditemukan" };
}

function verifySPP(idSpp, status, verifiedBy) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("SPP");
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idxId = headers.indexOf("ID_SPP");

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][idxId]) === String(idSpp)) {
      const rowNum = i + 1;
      sheet.getRange(rowNum, headers.indexOf("Status_Bayar") + 1).setValue(status || "Lunas");
      sheet.getRange(rowNum, headers.indexOf("Verified_By") + 1).setValue(verifiedBy || "Admin TU");
      return { success: true, message: "Status SPP berhasil diperbarui menjadi: " + status };
    }
  }
  return { success: false, message: "Tagihan SPP tidak ditemukan" };
}

/**
 * Upload File Bukti ke Google Drive
 */
function saveFileToDrive(base64Data, filename) {
  try {
    const folderName = "E-Bayyinah_Bukti_Transfer";
    const folders = DriveApp.getFoldersByName(folderName);
    let folder = folders.hasNext() ? folders.next() : DriveApp.createFolder(folderName);

    const contentType = filename.endsWith(".png") ? "image/png" : "image/jpeg";
    const decoded = Utilities.base64Decode(base64Data);
    const blob = Utilities.newBlob(decoded, contentType, filename);
    const file = folder.createFile(blob);
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    return file.getUrl();
  } catch (e) {
    return "Error Upload: " + e.toString();
  }
}

/**
 * Tracer Study & Legalisir Alumni
 */
function getTracerList(tahunLulus, search) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Tracer_Alumni");
  if (!sheet || sheet.getLastRow() <= 1) return { success: true, data: [] };

  const rows = sheet.getDataRange().getValues();
  const headers = rows[0];
  const idxThn = headers.indexOf("Tahun_Lulus");
  const list = [];

  for (let i = 1; i < rows.length; i++) {
    const r = rows[i];
    if (tahunLulus && String(r[idxThn]) !== String(tahunLulus)) continue;

    const obj = {};
    headers.forEach((h, idx) => {
      let v = r[idx];
      if (v instanceof Date) v = Utilities.formatDate(v, Session.getScriptTimeZone(), "yyyy-MM-dd");
      obj[h.toLowerCase()] = v;
    });
    list.push(obj);
  }

  return { success: true, data: list };
}

function updateTracer(p) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Tracer_Alumni");
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idxIdSiswa = headers.indexOf("ID_Siswa");

  let foundRow = -1;
  for (let i = 1; i < data.length; i++) {
    if (String(data[i][idxIdSiswa]) === String(p.id_siswa)) {
      foundRow = i + 1;
      break;
    }
  }

  const idAlumni = p.id_alumni || ("ALM-" + (sheet.getLastRow()));
  const rowData = [
    idAlumni,
    p.id_siswa,
    p.nama_lengkap || "",
    p.tahun_lulus || new Date().getFullYear(),
    p.status_aktivitas || "Kuliah", // Kuliah, Bekerja, Wirausaha, Mencari_Kerja
    p.nama_instansi || "",
    p.bidang_jurusan || "",
    p.kontak || "",
    Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd"),
    p.status_legalisir || "Tidak Ada"
  ];

  if (foundRow > 0) {
    sheet.getRange(foundRow, 1, 1, rowData.length).setValues([rowData]);
  } else {
    sheet.appendRow(rowData);
  }

  return { success: true, message: "Data Tracer Study berhasil diperbarui" };
}

function requestLegalisir(p) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName("Tracer_Alumni");
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idxIdSiswa = headers.indexOf("ID_Siswa");

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][idxIdSiswa]) === String(p.id_siswa)) {
      const rowNum = i + 1;
      sheet.getRange(rowNum, headers.indexOf("Status_Legalisir") + 1).setValue("Diajukan - " + (p.dokumen || "Ijazah & Rapor"));
      return { success: true, message: "Permohonan legalisir digital berhasil diajukan ke TU" };
    }
  }

  return { success: false, message: "Data Alumni belum terdaftar di Tracer Study" };
}

/**
 * ==========================================================================
 * INITIALIZE DATABASE & DUMMY SAMPLE DATA
 * Eksekusi fungsi ini pertama kali untuk membuat seluruh sheet & contoh data
 * ==========================================================================
 */
function initializeDatabase() {
  const ss = getSpreadsheet();

  // 1. Sheet Users
  let sUsers = ss.getSheetByName("Users");
  if (!sUsers) {
    sUsers = ss.insertSheet("Users");
    sUsers.appendRow(["ID_User", "Username", "Password_Hash", "Role", "ID_Ref", "Full_Name", "Status", "Created_At"]);
    sUsers.appendRow(["USR-1", "admin", hashPassword("admin123"), "Admin", "", "Admin TU Al-Bayyinah", "Aktif", new Date()]);
    sUsers.appendRow(["USR-2", "guru01", hashPassword("guru123"), "Guru", "", "Ust. Ahmad Dahlan, S.Pd.I", "Aktif", new Date()]);
    sUsers.appendRow(["USR-3", "2024001", hashPassword("siswa123"), "Siswa", "SISWA-2024001", "Muhammad Raihan", "Aktif", new Date()]);
    sUsers.appendRow(["USR-4", "2021001", hashPassword("alumni123"), "Alumni", "SISWA-2021001", "Fajar Ramadhan", "Aktif", new Date()]);
  }

  // 2. Sheet Master_Angkatan
  let sAngkatan = ss.getSheetByName("Master_Angkatan");
  if (!sAngkatan) {
    sAngkatan = ss.insertSheet("Master_Angkatan");
    sAngkatan.appendRow(["ID_Angkatan", "Nama_Angkatan", "Tahun_Masuk", "Tahun_Lulus", "Total_Siswa", "Status", "Keterangan"]);
    sAngkatan.appendRow(["ANGK-1", "Angkatan 1 (Al-Fatih)", 2021, 2024, 32, "Lulus", "Angkatan Pertama Bersejarah"]);
    sAngkatan.appendRow(["ANGK-2", "Angkatan 2 (Al-Farabi)", 2022, 2025, 36, "Aktif", "Kelas XII Persiapan Kelulusan"]);
    sAngkatan.appendRow(["ANGK-3", "Angkatan 3 (Ar-Razi)", 2023, 2026, 40, "Aktif", "Kelas XI"]);
    sAngkatan.appendRow(["ANGK-4", "Angkatan 4 (Ibnu Sina)", 2024, 2027, 45, "Aktif", "Kelas X"]);
  }

  // 3. Sheet Data_Siswa
  let sSiswa = ss.getSheetByName("Data_Siswa");
  if (!sSiswa) {
    sSiswa = ss.insertSheet("Data_Siswa");
    sSiswa.appendRow(["ID_Siswa", "NIS", "NISN", "Nama_Lengkap", "ID_Angkatan", "Jenis_Kelamin", "Tempat_Lahir", "Tgl_Lahir", "Alamat", "No_HP", "Nama_Ortu", "Status"]);
    sSiswa.appendRow(["SISWA-2024001", "2024001", "0081234567", "Muhammad Raihan", "ANGK-4", "L", "Bandung", "2008-05-14", "Jl. Terusan Al-Bayyinah No. 12", "081234567890", "H. Abdullah", "Aktif"]);
    sSiswa.appendRow(["SISWA-2024002", "2024002", "0081234568", "Aisyah Nurul Izzah", "ANGK-4", "P", "Jakarta", "2008-08-20", "Jl. Pesantren Asri No. 5", "081298765432", "Drs. Ahmad Mansur", "Aktif"]);
    sSiswa.appendRow(["SISWA-2022001", "2022001", "0061234501", "Bilal Ramadhan", "ANGK-2", "L", "Bogor", "2006-11-02", "Komplek Hijau Blok B4", "085612345678", "Ir. Usman", "Aktif"]);
    sSiswa.appendRow(["SISWA-2021001", "2021001", "0051234999", "Fajar Ramadhan", "ANGK-1", "L", "Cimahi", "2005-02-18", "Jl. Raya Cihanjuang No. 88", "087812345678", "Supriyadi", "Lulus"]);
  }

  // 4. Sheet Presensi
  let sPresensi = ss.getSheetByName("Presensi");
  if (!sPresensi) {
    sPresensi = ss.insertSheet("Presensi");
    sPresensi.appendRow(["ID_Presensi", "Tanggal", "ID_Siswa", "Status_Hadir", "Jam_Scan", "Metode", "Lokasi"]);
    const today = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd");
    sPresensi.appendRow(["PRS-001", today, "SISWA-2024001", "Hadir", "06:48:12", "QR Code", "Gerbang Utama Al-Bayyinah"]);
    sPresensi.appendRow(["PRS-002", today, "SISWA-2024002", "Hadir", "06:52:40", "QR Code", "Gerbang Utama Al-Bayyinah"]);
    sPresensi.appendRow(["PRS-003", today, "SISWA-2022001", "Izin", "07:05:00", "Manual Guru", "Surat Sakit"]);
  }

  // 5. Sheet Nilai
  let sNilai = ss.getSheetByName("Nilai");
  if (!sNilai) {
    sNilai = ss.insertSheet("Nilai");
    sNilai.appendRow(["ID_Nilai", "ID_Siswa", "Semester", "Tahun_Ajaran", "Mata_Pelajaran", "Tugas", "UTS", "UAS", "Nilai_Akhir", "Predikat"]);
    sNilai.appendRow(["NIL-001", "SISWA-2024001", "Ganjil", "2024/2025", "Pendidikan Agama Islam", 90, 88, 92, 90, "A"]);
    sNilai.appendRow(["NIL-002", "SISWA-2024001", "Ganjil", "2024/2025", "Bahasa Arab", 85, 80, 88, 85, "B"]);
    sNilai.appendRow(["NIL-003", "SISWA-2024001", "Ganjil", "2024/2025", "Matematika", 80, 85, 85, 84, "B"]);
    sNilai.appendRow(["NIL-004", "SISWA-2024001", "Ganjil", "2024/2025", "Bahasa Inggris", 92, 90, 95, 93, "A"]);
  }

  // 6. Sheet SPP
  let sSPP = ss.getSheetByName("SPP");
  if (!sSPP) {
    sSPP = ss.insertSheet("SPP");
    sSPP.appendRow(["ID_SPP", "ID_Siswa", "Bulan", "Tahun", "Nominal_Tagihan", "Nominal_Bayar", "Tgl_Bayar", "Status_Bayar", "Bukti_Url", "Verified_By"]);
    sSPP.appendRow(["SPP-202407", "SISWA-2024001", "Juli", 2024, 350000, 350000, "2024-07-10", "Lunas", "", "Admin TU"]);
    sSPP.appendRow(["SPP-202408", "SISWA-2024001", "Agustus", 2024, 350000, 350000, "2024-08-08", "Lunas", "", "Admin TU"]);
    sSPP.appendRow(["SPP-202409", "SISWA-2024001", "September", 2024, 350000, 0, "", "Belum_Bayar", "", ""]);
    sSPP.appendRow(["SPP-202410", "SISWA-2024001", "Oktober", 2024, 350000, 0, "", "Belum_Bayar", "", ""]);
  }

  // 7. Sheet Tracer_Alumni
  let sTracer = ss.getSheetByName("Tracer_Alumni");
  if (!sTracer) {
    sTracer = ss.insertSheet("Tracer_Alumni");
    sTracer.appendRow(["ID_Alumni", "ID_Siswa", "Nama_Lengkap", "Tahun_Lulus", "Status_Aktivitas", "Nama_Instansi", "Bidang_Jurusan", "Kontak", "Tgl_Update", "Status_Legalisir"]);
    sTracer.appendRow(["ALM-001", "SISWA-2021001", "Fajar Ramadhan", 2024, "Kuliah", "Universitas Pendidikan Indonesia", "Pendidikan Bahasa Arab", "087812345678", "2024-08-15", "Selesai Legalisir"]);
  }

  return {
    success: true,
    message: "Inisialisasi Database SIMS E-Bayyinah berhasil! Seluruh sheet dan data dummy siap digunakan."
  };
}
