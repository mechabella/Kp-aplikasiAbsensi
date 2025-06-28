import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'permission_management_screen.dart';
import 'history_attendance_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<Map<String, dynamic>> users = [];
  String? errorMessage;
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final loadedUsers = await authService.getAllUsers();
      setState(() {
        users = loadedUsers;
        errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        users = [];
        errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserData(user!.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (userSnapshot.hasError || !userSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Gagal memuat data pengguna')),
          );
        }

        final userData = userSnapshot.data!;
        final role = userData['role'] ?? 'karyawan';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Kelola User'),
            backgroundColor: const Color(0xFF001F54),
            foregroundColor: Colors.white,
            actions: [
              if (role == 'hrd')
                IconButton(
                  icon: const Icon(Icons.note, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PermissionManagementScreen()),
                    );
                  },
                  tooltip: 'Kelola Pengajuan Izin',
                ),
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HistoryAttendanceScreen()),
                  );
                },
                tooltip: 'Riwayat Absensi',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(errorMessage!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadUsers,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF001F54),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
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
                                    'Tambah User',
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
                                  backgroundImage: user['fotoUrl'] != null &&
                                          user['fotoUrl'].isNotEmpty
                                      ? NetworkImage(user['fotoUrl'])
                                      : const AssetImage('assets/default_profile.png')
                                          as ImageProvider,
                                ),
                                title: Text(user['nama'] ?? 'Unknown'),
                                subtitle: Text(
                                    '${user['id'] ?? ''} - ${user['jabatan'] ?? 'Unknown'}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showEditUserDialog(context, user),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () =>
                                          _showDeleteConfirmationDialog(context, user),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        );
      },
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
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Tambah User Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'ID Karyawan'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ID Karyawan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: jabatanController,
                  decoration: const InputDecoration(labelText: 'Jabatan'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Jabatan tidak boleh kosong';
                    }
                    return null;
                  },
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
                    setState(() {
                      role = value!;
                    });
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
                if (namaController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty ||
                    passwordController.text.trim().isEmpty ||
                    idController.text.trim().isEmpty ||
                    jabatanController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Harap isi semua field')),
                  );
                  return;
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Masukkan email yang valid')),
                  );
                  return;
                }
                if (passwordController.text.trim().length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password minimal 6 karakter')),
                  );
                  return;
                }

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
                  await _loadUsers();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Gagal menambahkan karyawan: ${result['error'] ?? 'Tidak diketahui'}')),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'ID Karyawan'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ID Karyawan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: jabatanController,
                  decoration: const InputDecoration(labelText: 'Jabatan'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Jabatan tidak boleh kosong';
                    }
                    return null;
                  },
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
                    setState(() {
                      role = value!;
                    });
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
                if (namaController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty ||
                    idController.text.trim().isEmpty ||
                    jabatanController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Harap isi semua field')),
                  );
                  return;
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Masukkan email yang valid')),
                  );
                  return;
                }

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
                  await _loadUsers();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(result['error'] ?? 'Gagal memperbarui karyawan')),
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
                await _loadUsers();
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