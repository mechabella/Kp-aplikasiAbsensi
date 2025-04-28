import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'clock_in_success_screen.dart';
import 'package:camera/camera.dart';

class ClockInConfirmationScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon user
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF001F54),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Pesan sukses
            const Text(
              'Clock-in Successful!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('HH:mm').format(DateTime.now()),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 16),
            const Text(
              'You have successfully clocked-in!\nHead back to Home to begin your task.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // Tombol Back to Home
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClockInSuccessScreen(
                      imageFile: imageFile,
                      latitude: latitude,
                      longitude: longitude,
                      workStatus: workStatus,
                      timestamp: DateTime.now(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001F54),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Back to Home'),
            ),
            const SizedBox(height: 16),
            // Tautan View Employee's Attendance Log
            TextButton(
              onPressed: () {
                // Nanti akan diarahkan ke halaman riwayat absensi
                Navigator.popUntil(context, (route) => route.isFirst); // Kembali ke HomeScreen
              },
              child: const Text(
                "View Employee's Attendance Log",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}