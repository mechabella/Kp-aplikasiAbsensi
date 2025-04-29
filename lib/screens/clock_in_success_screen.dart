import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

class ClockInSuccessScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: const Color(0xFF001F54),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto yang diunggah
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: Image.file(
                File(imageFile.path),
                fit: BoxFit.cover,
              ),
            ),
            // Detail absensi
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Notes', workStatus),
                  const SizedBox(height: 8),
                  _buildDetailRow('Location', '$latitude, $longitude'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Clock In',
                      DateFormat('dd MMMM yyyy, HH:mm').format(timestamp)),
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
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
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
