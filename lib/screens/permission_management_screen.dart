import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../models/permission.dart';

class PermissionManagementScreen extends StatelessWidget {
  const PermissionManagementScreen({super.key});

  Future<void> _updateStatus(BuildContext context, String permissionId, String status) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await authService.updatePermissionStatus(
      permissionId: permissionId,
      status: status,
      reviewedBy: user.uid,
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengajuan telah ${status == 'Approved' ? 'disetujui' : 'ditolak'}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Gagal memperbarui status')),
      );
    }
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Tidak dapat membuka file: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengajuan Izin'),
        backgroundColor: const Color(0xFF001F54),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Permission>>(
        future: authService.getAllPermissions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada pengajuan izin'));
          }

          final permissions = snapshot.data!;

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
                      Text(
                        'Pengajuan dari: ${permission.nama}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Jenis Izin: ${permission.type}'),
                      Text('Tanggal: ${DateFormat('dd MMMM yyyy').format(permission.fromDate)} - ${DateFormat('dd MMMM yyyy').format(permission.toDate)}'),
                      Text('Jumlah Hari: ${permission.duration}'),
                      Text('Catatan: ${permission.notes}'),
                      Text('Status: ${permission.status}'),
                      Text('Diajukan pada: ${DateFormat('dd MMMM yyyy, HH:mm').format(permission.submissionDate)}'),
                      if (permission.fileUrl.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            try {
                              await _openFile(permission.fileUrl);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          child: const Text('Lihat File Pendukung', style: TextStyle(color: Colors.blue)),
                        ),
                      if (permission.status == 'Pending')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _updateStatus(context, permission.id, 'Approved'),
                              child: const Text('Setujui', style: TextStyle(color: Colors.green)),
                            ),
                            TextButton(
                              onPressed: () => _updateStatus(context, permission.id, 'Rejected'),
                              child: const Text('Tolak', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}