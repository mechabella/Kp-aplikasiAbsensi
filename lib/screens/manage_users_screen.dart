import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_services.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Karyawan'),
        backgroundColor: const Color(0xFF001F54),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: authService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data karyawan'));
          }

          final users = snapshot.data!;

          return ListView.builder(
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
                  trailing: Text(user['role'] ?? 'Unknown'),
                ),
              );
            },
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
}