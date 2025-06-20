import 'package:absensi_app/models/permission.dart';
import 'package:absensi_app/screens/history_attendance_screen.dart';
import 'package:absensi_app/screens/permission_management_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../models/attendance.dart';
import 'manage_users_screen.dart';
import 'clock_in_screen.dart';
import 'clock_out_screen.dart';
import 'permission_request_screen.dart';
import 'permission_history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String _filter = 'All'; // Filter state: All, Late, Early Out, Permission
  int _displayCount = 5; // Number of records to display
  List<dynamic> _allHistory =
      []; // Store combined attendance and permission data

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        // Load more records when reaching the bottom
        setState(() {
          _displayCount += 5;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _checkLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan lokasi dinonaktifkan')),
        );
        return false;
      }

      // Check location permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak')),
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak secara permanen')),
        );
        return false;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Target location: -2.9836591445568796, 104.75457950303665
      const double targetLat = -2.9836591445568796;
      const double targetLon = 104.75457950303665;
      const double maxDistance = 100; // 100 meters

      // Calculate distance
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLon,
      );

      if (distance > maxDistance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Anda berada di luar lokasi absensi yang diizinkan')),
        );
        return false;
      }

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memeriksa lokasi: $e')),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF001F54),
      statusBarIconBrightness: Brightness.light,
    ));

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: Text('Silakan login terlebih dahulu')));
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: authService.getUserData(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
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
                    _buildHeader(context, userData, authService, role),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => setState(() {}),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              _buildAttendanceCard(
                                  context, role, snapshot.data!.uid),
                              const SizedBox(height: 20),
                              _buildAttendanceHistory(
                                  authService, snapshot.data!.uid),
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

  Widget _buildHeader(BuildContext context, Map<String, dynamic> userData,
      AuthService authService, String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF001F54),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData['nama'] ?? 'Nilam',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  userData['id'] != null
                      ? "${userData['id']} - ${userData['jabatan'] ?? ''}"
                      : "123456789 - Junior UX Designer",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (role == 'kepala_cabang')
            IconButton(
              icon: const Icon(Icons.people, color: Colors.white, size: 22),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ManageUsersScreen()),
              ),
              tooltip: 'Kelola Pengguna',
            ),
          if (role == 'karyawan') ...[
            IconButton(
              icon: const Icon(Icons.note_add, color: Colors.white, size: 22),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PermissionRequestScreen()),
              ),
              tooltip: 'Ajukan Izin',
            ),
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white, size: 22),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PermissionHistoryScreen()),
              ),
              tooltip: 'Riwayat Pengajuan Izin',
            ),
          ],
          if (role == 'hrd') ...[
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            onPressed: () async {
              await authService.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, String role, String uid) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Live Attendance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            StreamBuilder<DateTime>(
              stream: Stream.periodic(
                  const Duration(seconds: 1), (_) => DateTime.now()),
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
            Text(
              DateFormat('EEE, dd MMMM yyyy').format(DateTime.now()),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 20),
            const Text(
              'Office Hours',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '08:00 AM - 05:00 PM',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, bool>>(
              future: _checkAttendanceStatus(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final hasClockedIn = snapshot.data?['hasClockedIn'] ?? false;
                final hasClockedOut = snapshot.data?['hasClockedOut'] ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasClockedIn ? Icons.check_circle : Icons.error_outline,
                      color: hasClockedIn ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasClockedIn ? 'Clocked In' : 'Not Clocked In',
                      style: TextStyle(
                        fontSize: 14,
                        color: hasClockedIn ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      hasClockedOut ? Icons.check_circle : Icons.error_outline,
                      color: hasClockedOut ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasClockedOut ? 'Clocked Out' : 'Not Clocked Out',
                      style: TextStyle(
                        fontSize: 14,
                        color: hasClockedOut ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            FutureBuilder<Map<String, bool>>(
              future: _checkAttendanceStatus(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final hasClockedIn = snapshot.data?['hasClockedIn'] ?? false;
                final hasClockedOut = snapshot.data?['hasClockedOut'] ?? false;
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (hasClockedIn) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Anda sudah melakukan Clock In hari ini'),
                              ),
                            );
                            return;
                          }
                          // Check location before allowing clock-in
                          final isInLocation = await _checkLocation();
                          if (!isInLocation) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Anda tidak berada di lokasi'),
                              ),
                            );
                            return;
                          }
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ClockInScreen()),
                          );
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasClockedIn
                              ? Colors.green
                              : const Color(0xFF001F54),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                        child: const Text(
                          'Clock In',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!hasClockedIn) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Anda belum melakukan Clock In hari ini'),
                              ),
                            );
                            return;
                          }
                          if (hasClockedOut) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Anda sudah melakukan Clock Out hari ini'),
                              ),
                            );
                            return;
                          }
                          // Check location before allowing clock-out
                          final isInLocation = await _checkLocation();
                          if (!isInLocation) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Anda tidak berada di lokasi'),
                              ),
                            );
                            return;
                          }
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ClockOutScreen()),
                          );
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasClockedOut
                              ? Colors.green
                              : const Color(0xFF001F54),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                        child: const Text(
                          'Clock Out',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, bool>> _checkAttendanceStatus(String uid) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final startOfDay = DateTime.parse('$today 00:00:00');
    final endOfDay = DateTime.parse('$today 23:59:59');

    final authService = Provider.of<AuthService>(context, listen: false);
    final attendanceList = await authService.getUserAttendance(uid);

    bool hasClockedIn = false;
    bool hasClockedOut = false;

    for (var attendance in attendanceList) {
      if (attendance.timestamp.isAfter(startOfDay) &&
          attendance.timestamp.isBefore(endOfDay)) {
        if (attendance.type == 'clock_in') {
          hasClockedIn = true;
        } else if (attendance.type == 'clock_out') {
          hasClockedOut = true;
        }
      }
    }

    return {'hasClockedIn': hasClockedIn, 'hasClockedOut': hasClockedOut};
  }

  Widget _buildAttendanceHistory(AuthService authService, String uid) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, size: 20, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _filter,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('Semua')),
                      DropdownMenuItem(value: 'Late', child: Text('Terlambat')),
                      DropdownMenuItem(
                          value: 'Early Out', child: Text('Pulang Cepat')),
                      DropdownMenuItem(
                          value: 'Permission', child: Text('Izin')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filter = value!;
                        _displayCount = 5; // Reset pagination on filter change
                      });
                    },
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.refresh, size: 20, color: Colors.blue),
                    onPressed: () => setState(() {
                      _displayCount = 5; // Reset pagination on refresh
                    }),
                    tooltip: 'Refresh Riwayat',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Attendance & Permission List
          FutureBuilder<List<dynamic>>(
            future: _fetchCombinedHistory(authService, uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy,
                            size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada data absensi atau izin',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final combinedHistory = snapshot.data!;
              final filteredHistory = combinedHistory.where((item) {
                if (item is Attendance) {
                  final clockIn = item.timestamp;
                  final isLate = _isLate(clockIn);
                  final isEarlyOut =
                      _isEarlyOut(null); // Adjust if clock-out needed
                  if (_filter == 'Late') return isLate;
                  if (_filter == 'Early Out') return isEarlyOut;
                  return _filter == 'All' || _filter == 'Permission';
                } else if (item is Permission) {
                  return _filter == 'All' || _filter == 'Permission';
                }
                return false;
              }).toList();

              if (filteredHistory.isEmpty) {
                return const Center(
                    child: Text('Tidak ada data untuk status ini'));
              }

              return ListView.separated(
                controller: _scrollController,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredHistory.length +
                    (filteredHistory.length < combinedHistory.length ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == filteredHistory.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final item = filteredHistory[index];
                  if (item is Attendance) {
                    final dateKey =
                        DateFormat('yyyy-MM-dd').format(item.timestamp);
                    final isLate = _isLate(item.timestamp);
                    final hasIssue = isLate;
                    return Container(
                      decoration: BoxDecoration(
                        color: hasIssue
                            ? Colors.red.withOpacity(0.05)
                            : Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasIssue
                              ? Colors.red.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasIssue
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                            ),
                            child: Center(
                              child: Text(
                                DateFormat('dd').format(item.timestamp),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: hasIssue ? Colors.red : Colors.blue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE, dd MMMM yyyy')
                                      .format(item.timestamp),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Absensi: ${item.type == 'clock_in' ? 'Clock In' : 'Clock Out'} - ${DateFormat('HH:mm').format(item.timestamp)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: hasIssue
                                        ? Colors.red[700]
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            hasIssue
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            color: hasIssue ? Colors.red : Colors.green,
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  } else if (item is Permission) {
                    final dateKey =
                        DateFormat('yyyy-MM-dd').format(item.fromDate);
                    final hasIssue = item.status == 'Rejected';
                    return Container(
                      decoration: BoxDecoration(
                        color: hasIssue
                            ? Colors.red.withOpacity(0.05)
                            : Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasIssue
                              ? Colors.red.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasIssue
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                            ),
                            child: Center(
                              child: Text(
                                DateFormat('dd').format(item.fromDate),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: hasIssue ? Colors.red : Colors.blue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Izin: ${item.type}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tanggal: ${DateFormat('dd MMMM yyyy').format(item.fromDate)} - ${DateFormat('dd MMMM yyyy').format(item.toDate)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: hasIssue
                                        ? Colors.red[700]
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Status: ${item.status}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: item.status == 'Approved'
                                        ? Colors.green
                                        : item.status == 'Rejected'
                                            ? Colors.red
                                            : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            hasIssue
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            color: hasIssue ? Colors.red : Colors.green,
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<List<dynamic>> _fetchCombinedHistory(
      AuthService authService, String uid) async {
    try {
      final attendanceList = await authService.getUserAttendance(uid);
      final permissionList = await authService.getUserPermissions(uid);
      return [...attendanceList, ...permissionList]..sort((a, b) =>
          (b is Attendance ? b.timestamp : b.fromDate)
              .compareTo(a is Attendance ? a.timestamp : a.fromDate));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching history: $e')),
      );
      return [];
    }
  }

  bool _isLate(DateTime? clockIn) {
    if (clockIn == null) return false;
    return clockIn.hour >= 8 && clockIn.minute > 0;
  }

  bool _isEarlyOut(DateTime? clockOut) {
    if (clockOut == null) return false;
    return clockOut.hour < 17 || (clockOut.hour == 17 && clockOut.minute == 0);
  }
}
