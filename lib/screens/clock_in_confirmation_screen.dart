import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/attendance.dart';
import 'clock_in_success_screen.dart';
import '../utils/drive_helper.dart';

class ClockInConfirmationScreen extends StatefulWidget {
  final XFile imageFile;
  final double latitude;
  final double longitude;
  final String workStatus;

  const ClockInConfirmationScreen({
    super.key,
    required this.imageFile,
    required this.latitude,
    required this.longitude,
    required this.workStatus,
  });

  @override
  _ClockInConfirmationScreenState createState() => _ClockInConfirmationScreenState();
}

class _ClockInConfirmationScreenState extends State<ClockInConfirmationScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _confirmClockIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Unggah foto ke Google Drive
      final file = File(widget.imageFile.path);
      final photoUrl = await DriveHelper.uploadToGoogleDrive(
        file,
        assetCredentialsPath: 'assets/absensiapp-123456789.json',
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
        type: 'clock_in',
      );

      final result = await authService.saveAttendance(attendance);
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Gagal menyimpan absensi');
      }

      // Navigasi ke ClockInSuccessScreen setelah sukses
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClockInSuccessScreen(
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
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background dengan garis vertikal
          Container(
            color: Colors.blue.shade50,
            child: Row(
              children: List.generate(
                10,
                (index) => Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.blue.shade100,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text('Error: $_errorMessage'))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Ikon user
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
                            // Pesan pratinjau
                            const Text(
                              'Confirm Clock-In',
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
                                "Please review your clock-in details. Press 'Confirm' to proceed.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Tombol Confirm
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: ElevatedButton(
                                onPressed: _confirmClockIn,
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
                            // Tautan Cancel
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
        ],
      ),
    );
  }
}