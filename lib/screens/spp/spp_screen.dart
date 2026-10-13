import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/spp_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spp_provider.dart';

class SPPScreen extends StatefulWidget {
  final String? targetStudentId;

  const SPPScreen({super.key, this.targetStudentId});

  @override
  State<SPPScreen> createState() => _SPPScreenState();
}

class _SPPScreenState extends State<SPPScreen> {
  int _selectedYear = 2024;
  String _selectedStatusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final spp = Provider.of<SPPProvider>(context, listen: false);
      final user = auth.currentUser;

      String? sId = widget.targetStudentId;
      if (sId == null && user != null && user.isSiswa) {
        sId = user.idRef ?? 'SISWA-2024001';
      }

      spp.fetchSPPList(
        idSiswa: sId,
        tahun: _selectedYear,
        statusBayar: _selectedStatusFilter,
      );
    });
  }

  void _showPaySPPDialog(BuildContext context, SPPModel item) {
    final sppProvider = Provider.of<SPPProvider>(context, listen: false);
    final nominalCtrl = TextEditingController(text: item.nominalTagihan.toStringAsFixed(0));
    bool isProofSelected = false;

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
                      Text(
                        'Bayar SPP ${item.bulan} ${item.tahun}',
                        style: const TextStyle(
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
                  const Text('Nominal Tagihan:'),
                  Text(
                    CurrencyFormatter.format(item.nominalTagihan),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Form Upload Bukti Transfer (FR-12)
                  const Text(
                    'Upload Bukti Transfer Bank / QRIS',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  InkWell(
                    onTap: () {
                      setModalState(() {
                        isProofSelected = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isProofSelected ? AppColors.success : AppColors.cardBorder,
                          width: isProofSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isProofSelected ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                            size: 40,
                            color: isProofSelected ? AppColors.success : AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isProofSelected
                                ? 'Bukti_Transfer_SPP_${item.bulan}.jpg Terpilih'
                                : 'Ketuk untuk pilih foto struk transfer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isProofSelected ? AppColors.success : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Format: JPG, PNG (Maks 5MB)',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final res = await sppProvider.paySPP(
                          idSpp: item.idSpp,
                          nominal: double.tryParse(nominalCtrl.text) ?? item.nominalTagihan,
                          fileBytes: isProofSelected ? [1, 2, 3] : null,
                          fileName: isProofSelected ? 'bukti_transfer.jpg' : null,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message']?.toString() ?? 'Pembayaran terkirim!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      child: const Text('Kirim Bukti Pembayaran'),
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

  void _showVerifyDialog(BuildContext context, SPPModel item) {
    final spp = Provider.of<SPPProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Verifikasi SPP ${item.bulan} ${item.tahun}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID Siswa: ${item.idSiswa}'),
              Text('Nominal Tagihan: ${CurrencyFormatter.format(item.nominalTagihan)}'),
              Text('Nominal Dibayar: ${CurrencyFormatter.format(item.nominalBayar)}'),
              const SizedBox(height: 12),
              if (item.buktiUrl != null && item.buktiUrl!.isNotEmpty)
                const Text(
                  'Bukti Transfer telah diunggah ke Google Drive.',
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await spp.verifySPP(
                  idSpp: item.idSpp,
                  status: 'Belum_Bayar',
                  verifiedBy: auth.currentUser?.fullName ?? 'Admin TU',
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Tolak / Belum Lunas', style: TextStyle(color: AppColors.error)),
            ),
            ElevatedButton(
              onPressed: () async {
                await spp.verifySPP(
                  idSpp: item.idSpp,
                  status: 'Lunas',
                  verifiedBy: auth.currentUser?.fullName ?? 'Admin TU',
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Verifikasi LUNAS'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sppProvider = Provider.of<SPPProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrasi & SPP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => sppProvider.fetchSPPList(tahun: _selectedYear),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Tahun',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 2024, child: Text('Tahun 2024')),
                      DropdownMenuItem(value: 2025, child: Text('Tahun 2025')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedYear = val);
                        sppProvider.fetchSPPList(tahun: val, statusBayar: _selectedStatusFilter);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status Bayar',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('Semua')),
                      DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
                      DropdownMenuItem(value: 'Menunggu_Verifikasi', child: Text('Menunggu')),
                      DropdownMenuItem(value: 'Belum_Bayar', child: Text('Belum Lunas')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedStatusFilter = val);
                        sppProvider.fetchSPPList(tahun: _selectedYear, statusBayar: val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // SPP List
          Expanded(
            child: sppProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sppProvider.sppList.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada data tagihan SPP untuk filter ini',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sppProvider.sppList.length,
                        itemBuilder: (context, index) {
                          final item = sppProvider.sppList[index];
                          return _buildSPPCard(context, item, isAdmin);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSPPCard(BuildContext context, SPPModel item, bool isAdmin) {
    Color statusColor;
    Color statusBgColor;
    String statusText;

    if (item.isLunas) {
      statusColor = AppColors.success;
      statusBgColor = AppColors.successLight;
      statusText = 'LUNAS';
    } else if (item.isWaiting) {
      statusColor = AppColors.warning;
      statusBgColor = AppColors.warningLight;
      statusText = 'MENUNGGU VERIFIKASI';
    } else {
      statusColor = AppColors.error;
      statusBgColor = AppColors.errorLight;
      statusText = 'BELUM BAYAR';
    }

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
              Text(
                'SPP ${item.bulan} ${item.tahun}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nominal Tagihan', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(
                    CurrencyFormatter.format(item.nominalTagihan),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (item.tglBayar != null && item.tglBayar!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Tanggal Bayar', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(
                      item.tglBayar!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isAdmin && (item.isWaiting || item.isUnpaid))
                OutlinedButton(
                  onPressed: () => _showVerifyDialog(context, item),
                  child: const Text('Verifikasi Admin'),
                ),
              if (!item.isLunas && !isAdmin)
                ElevatedButton.icon(
                  onPressed: () => _showPaySPPDialog(context, item),
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: const Text('Upload Bukti Transfer'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
