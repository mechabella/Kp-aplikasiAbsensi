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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.black),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
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
                        // Pesan sukses
                        const Text(
                          'Clock-In Successful!',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(DateTime.now()),
                          style: TextStyle(
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
                            "You're all set! Your clock-in was successful. Head over to Home to see your assigned tasks.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Tombol Back to Home
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: ElevatedButton(
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
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Back to Home'),
                          ),
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
                            style: TextStyle(color: Color(0xFF001F54)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}