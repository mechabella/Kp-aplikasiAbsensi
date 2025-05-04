import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/attendance.dart';
import '../models/permission.dart';

class EmployeeWorkHistoryScreen extends StatefulWidget {
  final String employeeUid;

  const EmployeeWorkHistoryScreen({super.key, required this.employeeUid});

  @override
  _EmployeeWorkHistoryScreenState createState() => _EmployeeWorkHistoryScreenState();
}

class _EmployeeWorkHistoryScreenState extends State<EmployeeWorkHistoryScreen> {
  String _filterType = 'All';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserData(widget.employeeUid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (userSnapshot.hasError || !userSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Gagal memuat data karyawan')),
          );
        }

        final userData = userSnapshot.data!;
        final role = userData['role'] ?? 'karyawan';
        final nama = userData['nama'] ?? 'Unknown';

        if (role == 'kepala_cabang' || role == 'karyawan') {
          return Scaffold(
            appBar: AppBar(
              title: Text('History Kerja - $nama'),
              backgroundColor: const Color(0xFF001F54),
              foregroundColor: Colors.white,
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    value: _filterType,
                    decoration: const InputDecoration(
                      labelText: 'Filter Tipe',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('Semua')),
                      DropdownMenuItem(value: 'Attendance', child: Text('Absensi')),
                      DropdownMenuItem(value: 'Permission', child: Text('Izin')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterType = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _fetchHistory(authService),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: ${snapshot.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => setState(() {}),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF001F54),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Tidak ada riwayat kerja'));
                      }

                      final history = snapshot.data!
                          .where((item) => _filterType == 'All' ||
                              (item is Attendance && _filterType == 'Attendance') ||
                              (item is Permission && _filterType == 'Permission'))
                          .toList();

                      if (history.isEmpty) {
                        return const Center(child: Text('Tidak ada data untuk tipe ini'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          if (item is Attendance) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Absensi',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text('Tanggal: ${DateFormat('dd MMMM yyyy, HH:mm').format(item.timestamp)}'),
                                  ],
                                ),
                              ),
                            );
                          } else if (item is Permission) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Izin',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text('Jenis Izin: ${item.type}'),
                                    Text(
                                      'Tanggal: ${DateFormat('dd MMMM yyyy').format(item.fromDate)} - ${DateFormat('dd MMMM yyyy').format(item.toDate)}',
                                    ),
                                    Text('Jumlah Hari: ${item.duration}'),
                                    Text('Catatan: ${item.notes}'),
                                    Text('Status: ${item.status}'),
                                    Text(
                                      'Diajukan pada: ${DateFormat('dd MMMM yyyy, HH:mm').format(item.submissionDate)}',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return const Scaffold(
          body: Center(child: Text('Akses ditolak')),
        );
      },
    );
  }

  Future<List<dynamic>> _fetchHistory(AuthService authService) async {
    final attendanceList = await authService.getUserAttendance(widget.employeeUid);
    final permissionList = await authService.getUserPermissions(widget.employeeUid);
    return [...attendanceList, ...permissionList];
  }
}