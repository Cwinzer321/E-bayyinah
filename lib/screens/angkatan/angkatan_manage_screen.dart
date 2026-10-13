import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../students/student_list_screen.dart';

class AngkatanManageScreen extends StatelessWidget {
  const AngkatanManageScreen({super.key});

  void _showAddAngkatanDialog(BuildContext context) {
    final sp = Provider.of<StudentProvider>(context, listen: false);
    final namaCtrl = TextEditingController(text: 'Angkatan ${sp.angkatanList.length + 1}');
    final tahunMasukCtrl = TextEditingController(text: '${DateTime.now().year}');
    final tahunLulusCtrl = TextEditingController(text: '${DateTime.now().year + 3}');
    final totalSiswaCtrl = TextEditingController(text: '40');
    final ketCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tambah Angkatan Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Angkatan'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tahunMasukCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tahun Masuk'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: tahunLulusCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tahun Lulus'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: totalSiswaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Estimasi Total Siswa'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ketCtrl,
                  decoration: const InputDecoration(labelText: 'Keterangan'),
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
                  'id_angkatan': 'ANGK-${sp.angkatanList.length + 1}',
                  'nama_angkatan': namaCtrl.text.trim(),
                  'tahun_masuk': int.tryParse(tahunMasukCtrl.text) ?? DateTime.now().year,
                  'tahun_lulus': int.tryParse(tahunLulusCtrl.text) ?? (DateTime.now().year + 3),
                  'total_siswa': int.tryParse(totalSiswaCtrl.text) ?? 0,
                  'status': 'Aktif',
                  'keterangan': ketCtrl.text.trim(),
                };
                final ok = await sp.saveAngkatan(payload);
                if (ok && ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Angkatan baru berhasil ditambahkan!'),
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
    final studentProvider = Provider.of<StudentProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Angkatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => studentProvider.fetchAngkatanList(),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddAngkatanDialog(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Angkatan Baru', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: studentProvider.angkatanList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: studentProvider.angkatanList.length,
              itemBuilder: (context, index) {
                final a = studentProvider.angkatanList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: a.isLulus ? AppColors.accentGoldLight : AppColors.primaryLight,
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: a.isLulus ? AppColors.accentGold : AppColors.primary,
                        ),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            a.namaAngkatan,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: a.isLulus ? AppColors.infoLight : AppColors.successLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            a.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: a.isLulus ? AppColors.info : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          'Tahun Masuk: ${a.tahunMasuk}  •  Tahun Lulus: ${a.tahunLulus}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kapasitas: ${a.totalSiswa} Siswa terdaftar',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        if (a.keterangan != null && a.keterangan!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Catatan: ${a.keterangan}',
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                    onTap: () {
                      studentProvider.setSelectedAngkatan(a.idAngkatan);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentListScreen(initialAngkatanId: a.idAngkatan),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
