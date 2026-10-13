import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/student_model.dart';
import '../../providers/student_provider.dart';

class StudentFormScreen extends StatefulWidget {
  final StudentModel? student;

  const StudentFormScreen({super.key, this.student});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nisController;
  late TextEditingController _nisnController;
  late TextEditingController _namaController;
  late TextEditingController _tempatLahirController;
  late TextEditingController _tglLahirController;
  late TextEditingController _alamatController;
  late TextEditingController _noHpController;
  late TextEditingController _namaOrtuController;

  String _idAngkatan = 'ANGK-4';
  String _jenisKelamin = 'L';
  String _status = 'Aktif';

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _nisController = TextEditingController(text: s?.nis ?? '');
    _nisnController = TextEditingController(text: s?.nisn ?? '');
    _namaController = TextEditingController(text: s?.namaLengkap ?? '');
    _tempatLahirController = TextEditingController(text: s?.tempatLahir ?? '');
    _tglLahirController = TextEditingController(text: s?.tglLahir ?? '2008-01-01');
    _alamatController = TextEditingController(text: s?.alamat ?? '');
    _noHpController = TextEditingController(text: s?.noHp ?? '');
    _namaOrtuController = TextEditingController(text: s?.namaOrtu ?? '');

    if (s != null) {
      _idAngkatan = s.idAngkatan;
      _jenisKelamin = s.jenisKelamin;
      _status = s.status;
    }
  }

  @override
  void dispose() {
    _nisController.dispose();
    _nisnController.dispose();
    _namaController.dispose();
    _tempatLahirController.dispose();
    _tglLahirController.dispose();
    _alamatController.dispose();
    _noHpController.dispose();
    _namaOrtuController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final sp = Provider.of<StudentProvider>(context, listen: false);

    final payload = {
      if (widget.student != null) 'id_siswa': widget.student!.idSiswa,
      'nis': _nisController.text.trim(),
      'nisn': _nisnController.text.trim(),
      'nama_lengkap': _namaController.text.trim(),
      'id_angkatan': _idAngkatan,
      'jenis_kelamin': _jenisKelamin,
      'tempat_lahir': _tempatLahirController.text.trim(),
      'tgl_lahir': _tglLahirController.text.trim(),
      'alamat': _alamatController.text.trim(),
      'no_hp': _noHpController.text.trim(),
      'nama_ortu': _namaOrtuController.text.trim(),
      'status': _status,
    };

    final success = await sp.saveStudent(payload);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data siswa berhasil disimpan ke Google Sheets!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = Provider.of<StudentProvider>(context);
    final isEdit = widget.student != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Data Siswa' : 'Tambah Siswa Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                      'Identitas Siswa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // NIS & NISN
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('NIS *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nisController,
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                                decoration: const InputDecoration(hintText: '2024001'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('NISN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nisnController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(hintText: '0081234567'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Nama Lengkap
                    const Text('Nama Lengkap *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _namaController,
                      validator: (v) => v!.isEmpty ? 'Nama lengkap wajib diisi' : null,
                      decoration: const InputDecoration(hintText: 'Contoh: Muhammad Raihan'),
                    ),

                    const SizedBox(height: 16),

                    // Angkatan & Jenis Kelamin
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Angkatan *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _idAngkatan,
                                items: sp.angkatanList.isEmpty
                                    ? [
                                        const DropdownMenuItem(value: 'ANGK-4', child: Text('Angkatan 4')),
                                        const DropdownMenuItem(value: 'ANGK-3', child: Text('Angkatan 3')),
                                        const DropdownMenuItem(value: 'ANGK-2', child: Text('Angkatan 2')),
                                        const DropdownMenuItem(value: 'ANGK-1', child: Text('Angkatan 1')),
                                      ]
                                    : sp.angkatanList
                                        .map((a) => DropdownMenuItem(
                                              value: a.idAngkatan,
                                              child: Text(a.namaAngkatan),
                                            ))
                                        .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _idAngkatan = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jenis Kelamin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _jenisKelamin,
                                items: const [
                                  DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                                  DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _jenisKelamin = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tempat, Tgl Lahir
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tempat Lahir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _tempatLahirController,
                                decoration: const InputDecoration(hintText: 'Bandung'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tgl Lahir (YYYY-MM-DD)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _tglLahirController,
                                decoration: const InputDecoration(hintText: '2008-05-14'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Orang Tua & Kontak
                    const Text('Nama Orang Tua / Wali', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _namaOrtuController,
                      decoration: const InputDecoration(hintText: 'Nama ayah / ibu'),
                    ),

                    const SizedBox(height: 16),

                    const Text('Nomor WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _noHpController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: '081234567890'),
                    ),

                    const SizedBox(height: 16),

                    const Text('Alamat Lengkap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _alamatController,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Jalan, RT/RW, Kelurahan, Kota'),
                    ),

                    const SizedBox(height: 16),

                    const Text('Status Siswa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _status,
                      items: const [
                        DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                        DropdownMenuItem(value: 'Lulus', child: Text('Lulus (Alumni)')),
                        DropdownMenuItem(value: 'Pindah', child: Text('Pindah Sekolah')),
                        DropdownMenuItem(value: 'Keluar', child: Text('Keluar')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: sp.isLoading ? null : _handleSave,
                  child: sp.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? 'Simpan Perubahan' : 'Tambahkan Siswa'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
