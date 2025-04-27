import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_services.dart';
import 'manage_users_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Set status bar to match the dark blue header
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF001F54),
      statusBarIconBrightness: Brightness.light,
    ));

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Silakan login terlebih dahulu')),
          );
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: authService.getUserData(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (userSnapshot.hasError || !userSnapshot.hasData) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Gagal memuat data pengguna')),
              );
            }

            final userData = userSnapshot.data!;
            final role = userData['role'] ?? 'karyawan';

            return Scaffold(
              backgroundColor: const Color(0xFF001F54),
              body: SafeArea(
                child: Column(
                  children: [
                    // Header dengan user info dan logout button
                    _buildHeader(context, userData, authService, role),
                    // Main content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              // Attendance Card
                              _buildAttendanceCard(context, role),
                              const SizedBox(height: 20),
                              // Attendance History (dengan white background)
                              _buildAttendanceHistory(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> userData, AuthService authService, String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF001F54), // Dark navy blue
      child: Row(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 18,
            backgroundImage: userData['fotoUrl'] != null && userData['fotoUrl'].isNotEmpty
                ? NetworkImage(userData['fotoUrl'])
                : const AssetImage('assets/default_profile.png') as ImageProvider,
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData['nama'] ?? 'Jacob Jones',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  userData['id'] != null ? "${userData['id']} - ${userData['jabatan'] ?? ''}" : "123456789 - Junior UX Designer",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Tombol navigasi ke ManageUsersScreen (hanya untuk kepala cabang)
          if (role == 'kepala_cabang')
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.people, color: Colors.white, size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageUsersScreen()),
                  );
                },
              ),
            ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            onPressed: () async {
              await authService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, String role) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Live Attendance Text
            const Text(
              'Live Attendance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Current Time - CENTERED
            StreamBuilder<DateTime>(
              stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text(
                    '09:41 AM',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  );
                }
                return Text(
                  DateFormat('hh:mm a').format(snapshot.data!),
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                );
              },
            ),
            // Current Date - CENTERED
            Text(
              DateFormat('EEE, dd MMMM yyyy').format(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            // Satu-satunya Divider/pemisah
            Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
            const SizedBox(height: 24),
            // Office Hours Text
            const Text(
              'Office Hours',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Office Hours Time
            const Text(
              '08:00 AM - 05:00 PM',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            // Clock In/Out Buttons dengan height lebih besar
            Row(
              children: [
                // Clock In Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: role == 'karyawan'
                        ? () {
                            // Navigate to attendance screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AttendanceScreen(),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001F54),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: const Text(
                      'Clock In',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Clock Out Button
                Expanded(
                  child: Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: role == 'karyawan'
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Clock Out (coming soon)')),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001F54),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: const Text(
                        'Clock Out',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceHistory() {
    final List<Map<String, dynamic>> attendanceData = [
      {'date': 'Mon, 18 April 2023', 'time': '08:00 - 05:00 PM', 'isLate': false},
      {'date': 'Fri, 15 April 2023', 'time': '08:52 - 05:00 PM', 'isLate': true},
      {'date': 'Thu, 14 April 2023', 'time': '07:45 - 05:00 PM', 'isLate': false},
      {'date': 'Wed, 13 April 2023', 'time': '07:55 - 05:00 PM', 'isLate': false},
      {'date': 'Tue, 12 April 2023', 'time': '08:48 - 05:00 PM', 'isLate': true},
      {'date': 'Mon, 11 April 2023', 'time': '07:52 - 05:00 PM', 'isLate': false},
    ];

    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance History Header with Icon
          Row(
            children: [
              const Icon(
                Icons.history,
                size: 18,
                color: Colors.black54,
              ),
              const SizedBox(width: 8),
              const Text(
                'Attendance History',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Attendance History List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attendanceData.length,
            itemBuilder: (context, index) {
              final item = attendanceData[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['date'] as String? ?? 'Unknown Date',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      item['time'] as String? ?? 'Unknown Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: (item['isLate'] as bool? ?? false) ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: const Color(0xFF001F54),
      ),
      body: const Center(
        child: Text('Attendance Screen (coming soon)'),
      ),
    );
  }
}