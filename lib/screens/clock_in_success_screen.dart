import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_services.dart';
import 'package:camera/camera.dart';
import '../models/attendance.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

class ClockInSuccessScreen extends StatefulWidget {
  final XFile imageFile;
  final double latitude;
  final double longitude;
  final String workStatus;
  final DateTime timestamp;

  const ClockInSuccessScreen({
    super.key,
    required this.imageFile,
    required this.latitude,
    required this.longitude,
    required this.workStatus,
    required this.timestamp,
  });

  @override
  _ClockInSuccessScreenState createState() => _ClockInSuccessScreenState();
}

class _ClockInSuccessScreenState extends State<ClockInSuccessScreen> {
  bool _isLoading = true;
  String? _photoUrl;
  String? _errorMessage;

  // Google Drive folder ID (ganti dengan ID folder kamu di Google Drive)
  final String _folderId = 'YOUR_GOOGLE_DRIVE_FOLDER_ID';

  @override
  void initState() {
    super.initState();
    _submitAttendance();
  }

  Future<void> _submitAttendance() async {
    try {
      // Unggah foto ke Google Drive
      _photoUrl = await _uploadToGoogleDrive(widget.imageFile);
      if (_photoUrl == null) {
        throw Exception('Gagal mengunggah foto ke Google Drive');
      }

      // Simpan data absensi ke Firestore
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Pengguna tidak login');
      }

      final attendance = Attendance(
        id: '${user.uid}_${widget.timestamp.toIso8601String()}',
        uid: user.uid,
        photoUrl: _photoUrl!,
        latitude: widget.latitude,
        longitude: widget.longitude,
        timestamp: widget.timestamp,
        type: 'clock_in',
      );

      final result = await authService.saveAttendance(attendance);
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Gagal menyimpan absensi');
      }
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

  Future<String?> _uploadToGoogleDrive(XFile imageFile) async {
    try {
      final credentials = await DefaultAssetBundle.of(context).loadString('assets/absensiapp-123456789.json');
      final serviceAccountCredentials = ServiceAccountCredentials.fromJson(credentials);
      final scopes = [drive.DriveApi.driveFileScope];
      final authClient = await clientViaServiceAccount(serviceAccountCredentials, scopes);

      final driveApi = drive.DriveApi(authClient);

      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(tempDir.path, 'attendance_${DateTime.now().toIso8601String()}.jpg');
      await imageFile.saveTo(tempPath);

      final file = drive.File();
      file.name = path.basename(tempPath);
      file.parents = [_folderId];

      final stream = http.ByteStream(Stream.castFrom(File(tempPath).openRead()));
      final media = drive.Media(stream, await File(tempPath).length());
      final uploadedFile = await driveApi.files.create(file, uploadMedia: media);

      final fileId = uploadedFile.id;
      await driveApi.permissions.create(
        drive.Permission()..role = 'reader'..type = 'anyone',
        fileId!,
      );
      final fileDetails = await driveApi.files.get(fileId, $fields: 'webViewLink') as drive.File;
      final fileUrl = fileDetails.webViewLink;

      authClient.close();
      return fileUrl;
    } catch (e) {
      print('Error uploading to Google Drive: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: const Color(0xFF001F54),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto yang diunggah
                      Container(
                        height: 300,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Image.file(
                          File(widget.imageFile.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Detail absensi
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Notes', widget.workStatus),
                            const SizedBox(height: 8),
                            _buildDetailRow('Location', '${widget.latitude}, ${widget.longitude}'),
                            const SizedBox(height: 8),
                            _buildDetailRow('Clock In', DateFormat('dd MMMM yyyy, HH:mm').format(widget.timestamp)),
                          ],
                        ),
                      ),
                      // Tombol Back to Home
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF001F54),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Back to Home'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}