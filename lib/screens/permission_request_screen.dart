import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/permission.dart';
import '../utils/drive_helper.dart';

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  _PermissionRequestScreenState createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _fromDate;
  DateTime? _toDate;
  String _notes = '';
  String _type = 'Izin Sakit'; // Default jenis izin
  File? _file;
  String? _fileName;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          // Reset _toDate jika lebih awal dari _fromDate
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = null;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _file = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitPermission() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih tanggal mulai dan selesai')),
      );
      return;
    }
    if (_toDate!.isBefore(_fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal selesai tidak boleh sebelum tanggal mulai')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String fileUrl = '';
      if (_file != null) {
        // Unggah file ke Google Drive (folder untuk surat izin)
        fileUrl = await DriveHelper.uploadToGoogleDrive(
          _file!,
          assetCredentialsPath: 'assets/absensi-458109-453307b07c38.json',
          targetFolderId: DriveHelper.permissionFolderId, // Gunakan folder untuk surat izin
        ) ?? '';
        if (fileUrl.isEmpty) {
          throw Exception('Gagal mengunggah file ke Google Drive');
        }
      }

      // Hitung jumlah hari
      final duration = _toDate!.difference(_fromDate!).inDays + 1;

      // Ambil data pengguna
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Pengguna tidak login');
      }
      final userData = await authService.getUserData(user.uid);
      if (userData == null) {
        throw Exception('Gagal memuat data pengguna');
      }

      // Buat objek Permission
      final permission = Permission(
        id: '${user.uid}_${DateTime.now().toIso8601String()}',
        uid: user.uid,
        nama: userData['nama'] ?? '',
        fromDate: _fromDate!,
        toDate: _toDate!,
        duration: duration,
        notes: _notes,
        fileUrl: fileUrl,
        type: _type,
        status: 'Pending',
        submissionDate: DateTime.now(),
      );

      // Simpan ke Firestore
      final result = await authService.submitPermission(permission);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan izin berhasil dikirim')),
        );
        Navigator.pop(context);
      } else {
        throw Exception(result['error'] ?? 'Gagal mengajukan izin');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isImageFile(String fileName) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif'];
    final extension = fileName.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajukan Izin'),
        backgroundColor: const Color(0xFF001F54),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Jenis Izin
                    const Text('Jenis Izin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    DropdownButtonFormField<String>(
                      value: _type,
                      items: const [
                        DropdownMenuItem(value: 'Izin Sakit', child: Text('Izin Sakit')),
                        DropdownMenuItem(value: 'Cuti Tahunan', child: Text('Cuti Tahunan')),
                        DropdownMenuItem(value: 'Izin Pribadi', child: Text('Izin Pribadi')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _type = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tanggal Mulai
                    const Text('Tanggal Mulai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: _fromDate == null
                            ? 'Pilih tanggal'
                            : DateFormat('dd MMMM yyyy').format(_fromDate!),
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context, true),
                    ),
                    const SizedBox(height: 16),
                    // Tanggal Selesai
                    const Text('Tanggal Selesai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: _toDate == null
                            ? 'Pilih tanggal'
                            : DateFormat('dd MMMM yyyy').format(_toDate!),
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context, false),
                    ),
                    const SizedBox(height: 16),
                    // Jumlah Hari (hanya ditampilkan, dihitung otomatis)
                    if (_fromDate != null && _toDate != null)
                      Text(
                        'Jumlah Hari: ${_toDate!.difference(_fromDate!).inDays + 1}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    const SizedBox(height: 16),
                    // Catatan
                    const Text('Catatan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    TextFormField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan alasan izin',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harap masukkan alasan izin';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _notes = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Unggah File
                    const Text('File Pendukung (Opsional)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _fileName ?? 'Belum ada file yang dipilih',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF001F54),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Pilih File'),
                        ),
                      ],
                    ),
                    // Preview File jika gambar
                    if (_file != null && _fileName != null && _isImageFile(_fileName!))
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Image.file(
                          _file!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Tombol Submit
                    ElevatedButton(
                      onPressed: _submitPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001F54),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Ajukan Izin'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}