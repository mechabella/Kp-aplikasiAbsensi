import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;
import '../services/auth_service.dart';
import '../models/attendance.dart';
import 'clock_out_success_screen.dart';
import '../utils/drive_helper.dart';

class ClockOutConfirmationScreen extends StatefulWidget {
  final XFile imageFile;
  final double latitude;
  final double longitude;
  final String workStatus;

  const ClockOutConfirmationScreen({
    super.key,
    required this.imageFile,
    required this.latitude,
    required this.longitude,
    required this.workStatus,
  });

  @override
  _ClockOutConfirmationScreenState createState() => _ClockOutConfirmationScreenState();
}

class _ClockOutConfirmationScreenState extends State<ClockOutConfirmationScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _confirmClockOut() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verifikasi bahwa file gambar dapat dibaca
      final file = File(widget.imageFile.path);
      final verificationImage = img.decodeImage(await file.readAsBytes());
      if (verificationImage == null) {
        throw Exception('File gambar tidak valid sebelum diunggah');
      }
      print('Verifikasi sebelum unggah: Gambar valid');

      // Unggah foto ke Google Drive
      final photoUrl = await DriveHelper.uploadToGoogleDrive(
        file,
        assetCredentialsPath: 'assets/absensi-458109-453307b07c38.json',
        targetFolderId: DriveHelper.attendanceFolderId,
      );
      if (photoUrl == null) {
        throw Exception('Gagal mengunggah foto ke Google Drive');
      }

      // Simpan data absensi ke Firestore
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Pengguna tidak login');
      }

      final timestamp = DateTime.now();
      final attendance = Attendance(
        id: '${user.uid}_${timestamp.toIso8601String()}',
        uid: user.uid,
        photoUrl: photoUrl,
        latitude: widget.latitude,
        longitude: widget.longitude,
        timestamp: timestamp,
        type: 'clock_out', // Ubah type menjadi clock_out
      );

      final result = await authService.saveAttendance(attendance);
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Gagal menyimpan absensi');
      }

      // Navigasi ke ClockOutSuccessScreen setelah sukses
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClockOutSuccessScreen(
            imageFile: widget.imageFile,
            latitude: widget.latitude,
            longitude: widget.longitude,
            workStatus: widget.workStatus,
            timestamp: timestamp,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $_errorMessage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text('Error: $_errorMessage'))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF001F54),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Confirm Clock-Out',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('HH:mm').format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.0),
                          child: Text(
                            "Please review your clock-out details. Press 'Confirm' to proceed.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: ElevatedButton(
                            onPressed: _confirmClockOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF001F54),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Confirm'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Color(0xFF001F54)),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}