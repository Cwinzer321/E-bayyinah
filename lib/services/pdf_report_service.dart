import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/nilai_model.dart';
import '../models/student_model.dart';

class PdfReportService {
  static Future<Uint8List> generateRaporPdf({
    required StudentModel student,
    required List<NilaiModel> grades,
    required String semester,
    required String tahunAjaran,
  }) async {
    final pdf = pw.Document();

    double totalNilai = 0;
    for (var g in grades) {
      totalNilai += g.nilaiAkhir;
    }
    final rataRata = grades.isNotEmpty ? (totalNilai / grades.length).toStringAsFixed(1) : '0';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Kop Surat Sekolah
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.black, width: 2),
                  ),
                ),
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 55,
                      height: 55,
                      decoration: const pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColor.fromInt(0xFF0D5C3A),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'EB',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'YAYASAN PENDIDIKAN ISLAM AL-BAYYINAH',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF0D5C3A),
                            ),
                          ),
                          pw.Text(
                            'LAPORAN CAPAIAN KOMPETENSI SISWA (e-RAPOR)',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Jl. Terusan Al-Bayyinah, Kota Bandung | Email: admin@e-bayyinah.sch.id',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // Biodata Siswa Header
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF6F9F8),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfRow('Nama Lengkap', student.namaLengkap),
                          _buildPdfRow('NIS / NISN', '${student.nis} / ${student.nisn}'),
                          _buildPdfRow('Angkatan', student.idAngkatan),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfRow('Semester', semester),
                          _buildPdfRow('Tahun Ajaran', tahunAjaran),
                          _buildPdfRow('Status', student.status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // Tabel Capaian Nilai
              pw.Text(
                'A. CAPAIAN HASIL BELAJAR AKADEMIK',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
              ),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FlexColumnWidth(3.5),
                  2: const pw.FixedColumnWidth(48),
                  3: const pw.FixedColumnWidth(48),
                  4: const pw.FixedColumnWidth(48),
                  5: const pw.FixedColumnWidth(54),
                  6: const pw.FixedColumnWidth(45),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF0D5C3A),
                    ),
                    children: [
                      _buildHeaderCell('No'),
                      _buildHeaderCell('Mata Pelajaran', alignLeft: true),
                      _buildHeaderCell('Tugas (30%)'),
                      _buildHeaderCell('UTS (30%)'),
                      _buildHeaderCell('UAS (40%)'),
                      _buildHeaderCell('Akhir'),
                      _buildHeaderCell('Predikat'),
                    ],
                  ),
                  // Table Body
                  ...grades.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final g = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx % 2 == 0 ? PdfColor.fromInt(0xFFF9FAFB) : PdfColors.white,
                      ),
                      children: [
                        _buildDataCell('$idx'),
                        _buildDataCell(g.mataPelajaran, alignLeft: true),
                        _buildDataCell(g.tugas.toStringAsFixed(0)),
                        _buildDataCell(g.uts.toStringAsFixed(0)),
                        _buildDataCell(g.uas.toStringAsFixed(0)),
                        _buildDataCell(
                          g.nilaiAkhir.toStringAsFixed(0),
                          isBold: true,
                        ),
                        _buildDataCell(g.predikat, isBold: true),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 12),

              // Ringkasan Nilai
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Rata-rata Nilai Akhir: $rataRata',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColor.fromInt(0xFF0D5C3A),
                  ),
                ),
              ),

              pw.Spacer(),

              // Tanda Tangan
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Mengetahui,', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Orang Tua / Wali Murid', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 55),
                      pw.Text('( ................................... )', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Bandung, ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Kepala Sekolah Al-Bayyinah', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 55),
                      pw.Text('KH. Rahmat Hidayat, M.Ag', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('NIP. 197805122003121002', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 85,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 9)),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderCell(String text, {bool alignLeft = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildDataCell(String text, {bool alignLeft = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static Future<void> printOrShareRapor({
    required StudentModel student,
    required List<NilaiModel> grades,
    required String semester,
    required String tahunAjaran,
  }) async {
    final pdfBytes = await generateRaporPdf(
      student: student,
      grades: grades,
      semester: semester,
      tahunAjaran: tahunAjaran,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'e-Rapor_${student.nis}_${student.namaLengkap}.pdf',
    );
  }
}
