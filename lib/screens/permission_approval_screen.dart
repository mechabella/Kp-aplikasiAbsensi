import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../models/permission.dart';

class PermissionApprovalScreen extends StatefulWidget {
  const PermissionApprovalScreen({super.key});

  @override
  _PermissionApprovalScreenState createState() =>
      _PermissionApprovalScreenState();
}

class _PermissionApprovalScreenState extends State<PermissionApprovalScreen> {
  final TextEditingController _reviewNotesController = TextEditingController();
  String? _selectedPermissionId;

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

  Future<void> _updatePermissionStatus(
      AuthService authService, String permissionId, String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User tidak login')),
      );
      return;
    }

    String? reviewNotes = _selectedPermissionId == permissionId
        ? _reviewNotesController.text
        : null;
    if (newStatus == 'Rejected' && reviewNotes == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Catatan Penolakan'),
          content: TextField(
            controller: _reviewNotesController,
            decoration:
                const InputDecoration(labelText: 'Masukkan alasan penolakan'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                reviewNotes = _reviewNotesController.text;
                Navigator.pop(context);
                _performUpdate(authService, permissionId, newStatus, user.uid,
                    reviewNotes);
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      );
      _selectedPermissionId = permissionId;
      return;
    }

    _performUpdate(authService, permissionId, newStatus, user.uid, reviewNotes);
  }

  void _performUpdate(AuthService authService, String permissionId,
      String newStatus, String reviewedBy, String? reviewNotes) async {
    try {
      await authService.updatePermissionStatus(
        permissionId: permissionId,
        status: newStatus,
        reviewedBy: reviewedBy,
        reviewNotes: reviewNotes,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengajuan telah $newStatus')),
      );
      setState(() {});
      _reviewNotesController.clear();
      _selectedPermissionId = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e')),
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

    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserData(user.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (userSnapshot.hasError || !userSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Gagal memuat data pengguna')),
          );
        }

        final userData = userSnapshot.data!;
        final role = userData['role'] ?? 'karyawan';

        if (role != 'kepala_cabang' || role != 'hrd') {
          return const Scaffold(
            body: Center(
                child: Text(
                    'Hanya HRD dan Kepala Cabang yang dapat mengakses halaman ini')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Persetujuan Pengajuan Izin'),
            backgroundColor: const Color(0xFF001F54),
            foregroundColor: Colors.white,
          ),
          body: FutureBuilder<List<Permission>>(
            future: authService.getAllPermissions(),
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
                return const Center(child: Text('Belum ada pengajuan izin'));
              }

              final permissions = snapshot.data!
                  .where((permission) => permission.status == 'Pending')
                  .toList();

              if (permissions.isEmpty) {
                return const Center(
                    child: Text('Tidak ada pengajuan yang perlu disetujui'));
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
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text('Memuat data pengguna...');
                              }
                              final userData = userSnapshot.data;
                              return Text(
                                'Pengaju: ${userData?['nama'] ?? 'Unknown'} (${userData?['id'] ?? 'Unknown'})',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Jenis Izin: ${permission.type}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
                          if (permission.fileUrl != null &&
                              permission.fileUrl!.isNotEmpty)
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
                              child: const Text(
                                'Lihat File Pendukung',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          if (permission.reviewedBy != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  'Diulas oleh: ${permission.reviewedBy}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                                if (permission.reviewNotes != null)
                                  Text(
                                    'Catatan: ${permission.reviewNotes}',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black54),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () => _updatePermissionStatus(
                                    authService, permission.id, 'Approved'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Setujui'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _updatePermissionStatus(
                                    authService, permission.id, 'Rejected'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Tolak'),
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
      },
    );
  }

  @override
  void dispose() {
    _reviewNotesController.dispose();
    super.dispose();
  }
}
