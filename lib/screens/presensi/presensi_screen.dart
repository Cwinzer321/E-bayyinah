import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/presensi_provider.dart';
import '../../providers/student_provider.dart';

class PresensiScreen extends StatefulWidget {
  const PresensiScreen({super.key});

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  final _nisScanInputController = TextEditingController();
  String _selectedStatus = 'Hadir';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final presensi = Provider.of<PresensiProvider>(context, listen: false);
      final user = auth.currentUser;
      
      // Jika siswa login, ambil presensi miliknya saja
      if (user != null && user.isSiswa && user.idRef != null) {
        presensi.fetchHistory(idSiswa: user.idRef);
      } else {
        presensi.fetchHistory();
      }
    });
  }

  @override
  void dispose() {
    _nisScanInputController.dispose();
    super.dispose();
  }

  void _showScanQrModal(BuildContext context) {
    final sp = Provider.of<StudentProvider>(context, listen: false);
    final presensi = Provider.of<PresensiProvider>(context, listen: false);
    String selectedSiswaId = sp.students.isNotEmpty ? sp.students.first.idSiswa : 'SISWA-2024001';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pindai QR / Check-In Siswa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Scanner visual view
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFF072317),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 72,
                          color: AppColors.accentGold,
                        ),
                        Positioned(
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Arahkan kamera ke QR Siswa',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Pilihan Siswa / NIS
                  const Text('Pilih Siswa yang Hadir:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedSiswaId,
                    items: sp.students.isEmpty
                        ? [
                            const DropdownMenuItem(
                              value: 'SISWA-2024001',
                              child: Text('2024001 - Muhammad Raihan'),
                            ),
                          ]
                        : sp.students
                            .map((s) => DropdownMenuItem(
                                  value: s.idSiswa,
                                  child: Text('${s.nis} - ${s.namaLengkap}'),
                                ))
                            .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedSiswaId = val);
                    },
                  ),

                  const SizedBox(height: 12),

                  // Pilihan Status Hadir
                  const Text('Status Kehadiran:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'Hadir', child: Text('Hadir (Tepat Waktu)')),
                      DropdownMenuItem(value: 'Izin', child: Text('Izin (Ada Surat)')),
                      DropdownMenuItem(value: 'Sakit', child: Text('Sakit')),
                      DropdownMenuItem(value: 'Alpa', child: Text('Alpa (Tanpa Keterangan)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final res = await presensi.recordPresensi(
                          idSiswa: selectedSiswaId,
                          statusHadir: _selectedStatus,
                          metode: 'QR Code Scanner',
                          lokasi: 'Gerbang Utama Al-Bayyinah',
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message']?.toString() ?? 'Presensi tersimpan!'),
                              backgroundColor: res['success'] == true ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Simpan Kehadiran (LockService Sync)'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final presensiProvider = Provider.of<PresensiProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final canCheckIn = user?.isAdmin == true || user?.isGuru == true;

    int totalHadir = 0;
    int totalIzin = 0;
    int totalSakit = 0;
    for (var p in presensiProvider.history) {
      if (p.statusHadir.toLowerCase() == 'hadir') {
        totalHadir++;
      } else if (p.statusHadir.toLowerCase() == 'izin') {
        totalIzin++;
      } else if (p.statusHadir.toLowerCase() == 'sakit') {
        totalSakit++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Digital Siswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => presensiProvider.fetchHistory(),
          ),
        ],
      ),
      floatingActionButton: canCheckIn
          ? FloatingActionButton.extended(
              onPressed: () => _showScanQrModal(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
              label: const Text('Scan QR Siswa', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: Column(
        children: [
          // FR-08: Ringkasan Rekap Kehadiran
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildAttendanceStat('Hadir', '$totalHadir', AppColors.success, AppColors.successLight),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAttendanceStat('Izin', '$totalIzin', AppColors.info, AppColors.infoLight),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAttendanceStat('Sakit', '$totalSakit', AppColors.warning, AppColors.warningLight),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Riwayat Kehadiran (List)
          Expanded(
            child: presensiProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : presensiProvider.history.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada data riwayat presensi hari ini',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: presensiProvider.history.length,
                        itemBuilder: (context, index) {
                          final item = presensiProvider.history[index];
                          final isHadir = item.statusHadir.toLowerCase() == 'hadir';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: isHadir ? AppColors.successLight : AppColors.warningLight,
                                child: Icon(
                                  isHadir ? Icons.check_circle_outline : Icons.pending_outlined,
                                  color: isHadir ? AppColors.success : AppColors.warning,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.idSiswa,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    item.jamScan,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.tanggal} • ${item.metode}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    'Lokasi: ${item.lokasi}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isHadir ? AppColors.successLight : AppColors.warningLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.statusHadir,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isHadir ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String label, String count, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
