import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_services.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<Map<String, dynamic>> users = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final loadedUsers = await authService.getAllUsers();
      setState(() {
        users = loadedUsers;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        users = [];
        errorMessage = 'Gagal memuat data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Karyawan'),
        backgroundColor: const Color(0xFF001F54),
        foregroundColor: Colors.white,
      ),
      body: errorMessage != null
          ? Center(child: Text(errorMessage!))
          : users.isEmpty
              ? const Center(child: Text('Tidak ada data karyawan'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length + 1, // +1 untuk tombol tambah karyawan
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Tombol Tambah Karyawan
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddUserDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF001F54),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Tambah Karyawan',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }

                    final user = users[index - 1];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['fotoUrl'] != null && user['fotoUrl'].isNotEmpty
                              ? NetworkImage(user['fotoUrl'])
                              : const AssetImage('assets/default_profile.png') as ImageProvider,
                        ),
                        title: Text(user['nama'] ?? 'Unknown'),
                        subtitle: Text('${user['id'] ?? ''} - ${user['jabatan'] ?? 'Unknown'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditUserDialog(context, user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmationDialog(context, user),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final namaController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final idController = TextEditingController();
    final jabatanController = TextEditingController();
    String role = 'karyawan'; // Default role

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Karyawan Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'ID Karyawan'),
              ),
              TextField(
                controller: jabatanController,
                decoration: const InputDecoration(labelText: 'Jabatan'),
              ),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'karyawan', child: Text('Karyawan')),
                  DropdownMenuItem(value: 'hrd', child: Text('HRD')),
                  DropdownMenuItem(value: 'kepala_cabang', child: Text('Kepala Cabang')),
                ],
                onChanged: (value) {
                  role = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await authService.addUser(
                email: emailController.text.trim(),
                password: passwordController.text.trim(),
                nama: namaController.text.trim(),
                role: role,
                jabatan: jabatanController.text.trim(),
                id: idController.text.trim(),
              );

              if (result['success'] == true) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Karyawan berhasil ditambahkan')),
                );
                await _loadUsers(); // Refresh daftar pengguna
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['error'] ?? 'Gagal menambahkan karyawan')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001F54),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final namaController = TextEditingController(text: user['nama']);
    final emailController = TextEditingController(text: user['email']);
    final idController = TextEditingController(text: user['id']);
    final jabatanController = TextEditingController(text: user['jabatan']);
    String role = user['role'] ?? 'karyawan';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Karyawan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'ID Karyawan'),
              ),
              TextField(
                controller: jabatanController,
                decoration: const InputDecoration(labelText: 'Jabatan'),
              ),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'karyawan', child: Text('Karyawan')),
                  DropdownMenuItem(value: 'hrd', child: Text('HRD')),
                  DropdownMenuItem(value: 'kepala_cabang', child: Text('Kepala Cabang')),
                ],
                onChanged: (value) {
                  role = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await authService.updateUser(
                uid: user['uid'],
                email: emailController.text.trim(),
                nama: namaController.text.trim(),
                role: role,
                jabatan: jabatanController.text.trim(),
                id: idController.text.trim(),
              );

              if (result['success'] == true) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Karyawan berhasil diperbarui')),
                );
                await _loadUsers(); // Refresh daftar pengguna
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['error'] ?? 'Gagal memperbarui karyawan')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001F54),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus ${user['nama']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final result = await authService.deleteUser(user['uid']);
              if (result['success'] == true) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Karyawan berhasil dihapus')),
                );
                await _loadUsers(); // Refresh daftar pengguna
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['error'] ?? 'Gagal menghapus karyawan')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}