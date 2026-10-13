import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/student_model.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/pdf_report_service.dart';

class NilaiScreen extends StatefulWidget {
  final StudentModel? targetStudent;

  const NilaiScreen({super.key, this.targetStudent});

  @override
  State<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends State<NilaiScreen> {
  String _semester = 'Ganjil';
  String _tahunAjaran = '2024/2025';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final academic = Provider.of<AcademicProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;

      String idSiswa = widget.targetStudent?.idSiswa ??
          (user?.idRef ?? 'SISWA-2024001');

      academic.fetchNilaiList(
        idSiswa: idSiswa,
        semester: _semester,
        tahunAjaran: _tahunAjaran,
      );
    });
  }

  void _showAddNilaiDialog(BuildContext context, String currentSiswaId) {
    final academic = Provider.of<AcademicProvider>(context, listen: false);
    final mapelCtrl = TextEditingController(text: 'Pendidikan Agama Islam');
    final tugasCtrl = TextEditingController(text: '85');
    final utsCtrl = TextEditingController(text: '80');
    final uasCtrl = TextEditingController(text: '90');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Input Nilai Mapel Siswa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: mapelCtrl,
                  decoration: const InputDecoration(labelText: 'Mata Pelajaran'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tugasCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tugas (30%)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: utsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'UTS (30%)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: uasCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'UAS (40%)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final payload = {
                  'id_siswa': currentSiswaId,
                  'semester': _semester,
                  'tahun_ajaran': _tahunAjaran,
                  'mata_pelajaran': mapelCtrl.text.trim(),
                  'tugas': double.tryParse(tugasCtrl.text) ?? 0,
                  'uts': double.tryParse(utsCtrl.text) ?? 0,
                  'uas': double.tryParse(uasCtrl.text) ?? 0,
                };
                final res = await academic.saveNilai(payload);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message']?.toString() ?? 'Nilai berhasil disimpan!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final academic = Provider.of<AcademicProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final canEdit = user?.isAdmin == true || user?.isGuru == true;

    final effectiveStudent = widget.targetStudent ??
        StudentModel(
          idSiswa: user?.idRef ?? 'SISWA-2024001',
          nis: user?.username ?? '2024001',
          nisn: '0081234567',
          namaLengkap: user?.fullName ?? 'Muhammad Raihan',
          idAngkatan: 'ANGK-4',
          jenisKelamin: 'L',
          tempatLahir: 'Bandung',
          tglLahir: '2008-05-14',
          alamat: 'Jl. Terusan Al-Bayyinah No. 12',
          noHp: '081234567890',
          namaOrtu: 'H. Abdullah',
          status: 'Aktif',
        );

    double total = 0;
    for (var n in academic.nilaiList) {
      total += n.nilaiAkhir;
    }
    final rataRata = academic.nilaiList.isNotEmpty
        ? (total / academic.nilaiList.length).toStringAsFixed(1)
        : '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akademik & e-Rapor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Cetak / Unduh e-Rapor PDF',
            onPressed: () {
              PdfReportService.printOrShareRapor(
                student: effectiveStudent,
                grades: academic.nilaiList,
                semester: _semester,
                tahunAjaran: _tahunAjaran,
              );
            },
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showAddNilaiDialog(context, effectiveStudent.idSiswa),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
              label: const Text('Input Nilai', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: Column(
        children: [
          // Header Siswa & Filter Semester
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            effectiveStudent.namaLengkap,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'NIS: ${effectiveStudent.nis}  •  ${effectiveStudent.idAngkatan}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            rataRata,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            'Rata-rata',
                            style: TextStyle(fontSize: 10, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _semester,
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Ganjil', child: Text('Semester Ganjil')),
                          DropdownMenuItem(value: 'Genap', child: Text('Semester Genap')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _semester = val);
                            academic.fetchNilaiList(
                              idSiswa: effectiveStudent.idSiswa,
                              semester: val,
                              tahunAjaran: _tahunAjaran,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _tahunAjaran,
                        decoration: const InputDecoration(
                          labelText: 'Tahun Ajaran',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: '2024/2025', child: Text('2024/2025')),
                          DropdownMenuItem(value: '2023/2024', child: Text('2023/2024')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _tahunAjaran = val);
                            academic.fetchNilaiList(
                              idSiswa: effectiveStudent.idSiswa,
                              semester: _semester,
                              tahunAjaran: val,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Daftar Nilai Mata Pelajaran
          Expanded(
            child: academic.isLoading
                ? const Center(child: CircularProgressIndicator())
                : academic.nilaiList.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada nilai tercatat untuk semester ini',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: academic.nilaiList.length,
                        itemBuilder: (context, index) {
                          final item = academic.nilaiList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.mataPelajaran,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: item.predikat == 'A'
                                            ? AppColors.successLight
                                            : AppColors.infoLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Predikat ${item.predikat}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: item.predikat == 'A'
                                              ? AppColors.success
                                              : AppColors.info,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _buildGradeBox('Tugas', item.tugas.toStringAsFixed(0)),
                                    const SizedBox(width: 8),
                                    _buildGradeBox('UTS', item.uts.toStringAsFixed(0)),
                                    const SizedBox(width: 8),
                                    _buildGradeBox('UAS', item.uas.toStringAsFixed(0)),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Nilai Akhir', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                        Text(
                                          item.nilaiAkhir.toStringAsFixed(0),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Print Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  PdfReportService.printOrShareRapor(
                    student: effectiveStudent,
                    grades: academic.nilaiList,
                    semester: _semester,
                    tahunAjaran: _tahunAjaran,
                  );
                },
                icon: const Icon(Icons.print_rounded, size: 20),
                label: const Text('Cetak / Unduh e-Rapor PDF'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
