import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_services.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

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
              backgroundColor: Colors.white,
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header dengan waktu dan tombol logout
                    _buildHeader(context, authService),
                    // User Info
                    _buildUserInfo(context, userData),
                    // Office Hours dan Tombol Clock In/Out
                    _buildOfficeHours(context, role),
                    // Attendance History
                    _buildAttendanceHistory(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AuthService authService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      color: const Color(0xFF001F54), // Biru
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<DateTime>(
                stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text(
                      '00:00 AM',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    );
                  }
                  return Text(
                    DateFormat('hh:mm a').format(snapshot.data!),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  );
                },
              ),
              Text(
                DateFormat('EEE, d MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await authService.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, Map<String, dynamic> userData) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Foto Profil
          CircleAvatar(
            radius: 30,
            backgroundImage: userData['fotoUrl'] != null && userData['fotoUrl'].isNotEmpty
                ? NetworkImage(userData['fotoUrl'])
                : const AssetImage('assets/default_profile.png') as ImageProvider,
          ),
          const SizedBox(width: 16),
          // Nama, Jabatan, dan Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData['nama'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  userData['jabatan'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  userData['email'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Ikon menu (opsional)
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.grey),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menu (coming soon)')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeHours(BuildContext context, String role) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF001F54), // Biru
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text(
            'OFFICE HOURS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '08:00 AM - 05:00 PM',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: role == 'karyawan'
                    ? () {
                        // Navigasi ke halaman attendance
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AttendanceScreen(),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF001F54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Clock In'),
              ),
              Builder(
                builder: (context) => ElevatedButton(
                  onPressed: role == 'karyawan'
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Clock Out (coming soon)')),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF001F54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Clock Out'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHistory() {
    final List<Map<String, dynamic>> attendanceData = [
      {'date': 'Mon, 10 April 2023', 'time': '08:30 - 05:00 PM', 'isLate': false},
      {'date': 'Fri, 15 April 2023', 'time': '08:50 - 05:00 PM', 'isLate': false},
      {'date': 'Thu, 14 April 2023', 'time': '08:52 - 05:00 PM', 'isLate': false},
      {'date': 'Wed, 13 April 2023', 'time': '07:35 - 05:00 PM', 'isLate': false},
      {'date': 'Tue, 12 April 2023', 'time': '06:46 - 05:00 PM', 'isLate': true},
      {'date': 'Mon, 11 April 2023', 'time': '07:52 - 05:00 PM', 'isLate': false},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attendanceData.length,
            itemBuilder: (context, index) {
              final item = attendanceData[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['date'] as String? ?? 'Unknown Date',
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    Text(
                      item['time'] as String? ?? 'Unknown Time',
                      style: TextStyle(
                        fontSize: 14,
                        color: (item['isLate'] as bool? ?? false) ? Colors.red : Colors.black,
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
      appBar: AppBar(title: const Text('Attendance')),
      body: const Center(
        child: Text('Attendance Screen (coming soon)'),
      ),
    );
  }
}