import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';

class TracerScreen extends StatefulWidget {
  final int initialTab;

  const TracerScreen({super.key, this.initialTab = 0});

  @override
  State<TracerScreen> createState() => _TracerScreenState();
}

class _TracerScreenState extends State<TracerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _namaInstansiController = TextEditingController(text: 'Universitas Indonesia');
  final _bidangController = TextEditingController(text: 'Sastra Arab & Studi Islam');
  final _kontakController = TextEditingController(text: '087812345678');
  String _statusAktivitas = 'Kuliah';

  String _jenisDokumenLegalisir = 'Ijazah & Rapor Lengkap';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AcademicProvider>(context, listen: false).fetchTracerList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _namaInstansiController.dispose();
    _bidangController.dispose();
    _kontakController.dispose();
    super.dispose();
  }

  Future<void> _submitTracerUpdate() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final academic = Provider.of<AcademicProvider>(context, listen: false);
    final user = auth.currentUser;

    final payload = {
      'id_siswa': user?.idRef ?? 'SISWA-2021001',
      'nama_lengkap': user?.fullName ?? 'Fajar Ramadhan',
      'tahun_lulus': 2024,
      'status_aktivitas': _statusAktivitas,
      'nama_instansi': _namaInstansiController.text.trim(),
      'bidang_jurusan': _bidangController.text.trim(),
      'kontak': _kontakController.text.trim(),
    };

    final res = await academic.updateTracer(payload);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Tracer study berhasil diperbarui!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _submitLegalisir() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final academic = Provider.of<AcademicProvider>(context, listen: false);
    final user = auth.currentUser;

    final res = await academic.requestLegalisir(
      idSiswa: user?.idRef ?? 'SISWA-2021001',
      jenisDokumen: _jenisDokumenLegalisir,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Permohonan legalisir terkirim!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final academic = Provider.of<AcademicProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Alumni & Tracer Study'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.work_outline), text: 'Tracer Study'),
            Tab(icon: Icon(Icons.verified_outlined), text: 'Legalisir Digital'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: TRACER STUDY (FR-13)
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form Update Karier
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pembaruan Status Alumni (Tracer)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Bantu almamater memetakan keberhasilan lulusan angkatan pertama dst.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),

                      const Text('Aktivitas Saat Ini:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _statusAktivitas,
                        items: const [
                          DropdownMenuItem(value: 'Kuliah', child: Text('Melanjutkan Kuliah (PTN/PTS)')),
                          DropdownMenuItem(value: 'Bekerja', child: Text('Bekerja Profesional / Karyawan')),
                          DropdownMenuItem(value: 'Wirausaha', child: Text('Wirausaha / Bisnis Mandiri')),
                          DropdownMenuItem(value: 'Mencari_Kerja', child: Text('Mencari Pekerjaan')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _statusAktivitas = val);
                        },
                      ),

                      const SizedBox(height: 16),

                      const Text('Nama Kampus / Tempat Kerja / Usaha:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _namaInstansiController,
                        decoration: const InputDecoration(hintText: 'Contoh: Universitas Indonesia / PT Telkom'),
                      ),

                      const SizedBox(height: 16),

                      const Text('Program Studi / Posisi Jabatan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _bidangController,
                        decoration: const InputDecoration(hintText: 'Contoh: Teknik Informatika / Staf Keuangan'),
                      ),

                      const SizedBox(height: 16),

                      const Text('Nomor Kontak / WhatsApp Terkini:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _kontakController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(hintText: '081234567890'),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _submitTracerUpdate,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Simpan Pembaruan Data'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Data Rekan Alumni Lainnya',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                ...academic.tracerList.map((t) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryLight,
                          child: const Icon(Icons.school, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.namaLengkap,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${t.statusAktivitas}: ${t.namaInstansi}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              Text(
                                'Jurusan/Bidang: ${t.bidangJurusan}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // TAB 2: LEGALISIR DOKUMEN DIGITAL (FR-14)
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Permohonan Legalisir Digital',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ajukan legalisir dokumen resmi tanpa harus datang langsung ke sekolah.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),

                      const Text('Pilih Dokumen yang Dilegalisir:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _jenisDokumenLegalisir,
                        items: const [
                          DropdownMenuItem(value: 'Ijazah & Rapor Lengkap', child: Text('Ijazah & Rapor Lengkap')),
                          DropdownMenuItem(value: 'Ijazah Saja', child: Text('Ijazah Saja (10 Lembar)')),
                          DropdownMenuItem(value: 'Transkrip Nilai e-Rapor', child: Text('Transkrip Nilai e-Rapor')),
                          DropdownMenuItem(value: 'Surat Keterangan Lulus (SKL)', child: Text('Surat Keterangan Lulus (SKL)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _jenisDokumenLegalisir = val);
                        },
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.info, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Dokumen digital legalisir bertanda tangan elektronik dan QR verifikasi resmi akan diproses dalam 1-2 hari kerja.',
                                style: TextStyle(fontSize: 11, color: AppColors.info),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _submitLegalisir,
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Ajukan Permohonan Legalisir'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
