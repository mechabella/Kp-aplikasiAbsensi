import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../models/permission.dart';

class PermissionHistoryScreen extends StatefulWidget {
  const PermissionHistoryScreen({super.key});

  @override
  _PermissionHistoryScreenState createState() => _PermissionHistoryScreenState();
}

class _PermissionHistoryScreenState extends State<PermissionHistoryScreen> {
  String _filterStatus = 'All'; // Default filter

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka file: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pengajuan Izin'),
        backgroundColor: const Color(0xFF001F54),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _filterStatus,
              decoration: const InputDecoration(
                labelText: 'Filter Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('Semua')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Approved', child: Text('Disetujui')),
                DropdownMenuItem(value: 'Rejected', child: Text('Ditolak')),
              ],
              onChanged: (value) {
                setState(() {
                  _filterStatus = value!;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Permission>>(
              future: authService.getUserPermissions(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Error fetching permissions: ${snapshot.error}'); // Debugging
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
                  print('No permissions data for uid: ${user.uid}'); // Debugging
                  return const Center(child: Text('Belum ada pengajuan izin'));
                }

                final permissions = snapshot.data!
                    .where((permission) =>
                        _filterStatus == 'All' || permission.status == _filterStatus)
                    .toList();

                if (permissions.isEmpty) {
                  print('Filtered permissions empty for status: $_filterStatus'); // Debugging
                  return const Center(child: Text('Tidak ada data untuk status ini'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: permissions.length,
                  itemBuilder: (context, index) {
                    final permission = permissions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<Map<String, dynamic>?>(
                              future: authService.getUserData(permission.uid),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Text('Memuat nama pengaju...');
                                }
                                final nama = userSnapshot.data?['nama'] ?? permission.nama ?? 'Unknown';
                                return Text(
                                  'Pengaju: $nama',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Jenis Izin: ${permission.type}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tanggal: ${DateFormat('dd MMMM yyyy').format(permission.fromDate)} - ${DateFormat('dd MMMM yyyy').format(permission.toDate)}',
                            ),
                            Text('Jumlah Hari: ${permission.duration}'),
                            Text('Catatan: ${permission.notes}'),
                            Text(
                              'Status: ${permission.status}',
                              style: TextStyle(
                                color: permission.status == 'Approved'
                                    ? Colors.green
                                    : permission.status == 'Rejected'
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                            ),
                            Text(
                              'Diajukan pada: ${DateFormat('dd MMMM yyyy, HH:mm').format(permission.submissionDate)}',
                            ),
                            if (permission.fileUrl != null && permission.fileUrl!.isNotEmpty)
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await _openFile(permission.fileUrl!);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                },
                                child: const Text('Lihat File Pendukung',
                                    style: TextStyle(color: Colors.blue)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}