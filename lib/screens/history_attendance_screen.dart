import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../models/attendance.dart';

class HistoryAttendanceScreen extends StatefulWidget {
  const HistoryAttendanceScreen({super.key});

  @override
  _HistoryAttendanceScreenState createState() => _HistoryAttendanceScreenState();
}

class _HistoryAttendanceScreenState extends State<HistoryAttendanceScreen> {
  List<Attendance> _attendanceList = [];
  List<Map<String, dynamic>> _users = [];
  String _selectedUser = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final users = await authService.getAllUsers();
      final attendance = await authService.getAllAttendance();
      setState(() {
        _users = users;
        _attendanceList = attendance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? value = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (value != null) {
      setState(() {
        if (isStartDate) {
          // Set start date to beginning of day (00:00:00)
          _startDate = DateTime(value.year, value.month, value.day, 0, 0, 0);
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null; // Reset end date if it's before the new start date
          }
        } else {
          // Set end date to end of day (23:59:59)
          _endDate = DateTime(value.year, value.month, value.day, 23, 59, 59);
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tanggal selesai harus setelah tanggal mulai')),
            );
            _endDate = null;
          }
        }
      });
    }
  }

  void _clearDateFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _exportToExcel(List<Attendance> attendanceList, String type) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Riwayat Absensi'];

    sheet.appendRow([
      'Nama Karyawan',
      'Tanggal',
      'Status',
      'Catatan',
    ]);

    for (var attendance in attendanceList) {
      final user = _users.firstWhere((u) => u['uid'] == attendance.uid, orElse: () => {'nama': 'Unknown'});
      sheet.appendRow([
        user['nama'] ?? 'Unknown',
        DateFormat('dd MMMM yyyy, HH:mm').format(attendance.timestamp),
        attendance.type,
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes == null) return;

    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan direktori penyimpanan')),
      );
      return;
    }

    final fileName = 'riwayat_absensi_${type}_${DateTime.now().toIso8601String()}.xlsx';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(fileBytes);

    if (await Permission.storage.request().isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File disimpan di: ${file.path}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin penyimpanan ditolak')),
      );
    }
  }

  List<Attendance> _filterAttendance() {
    List<Attendance> filtered = _attendanceList.where((attendance) {
      // Filter by user
      bool passesUserFilter = _selectedUser == 'All' || attendance.uid == _selectedUser;
      
      // Filter by date range
      bool passesDateFilter = true;
      
      if (_startDate != null && _endDate != null) {
        // Both start and end date are set - check if attendance is within range
        DateTime attendanceDate = attendance.timestamp;
        bool afterStart = attendanceDate.isAfter(_startDate!) || attendanceDate.isAtSameMomentAs(_startDate!);
        bool beforeEnd = attendanceDate.isBefore(_endDate!) || attendanceDate.isAtSameMomentAs(_endDate!);
        passesDateFilter = afterStart && beforeEnd;
        
        // Debug print (remove in production)
        print('Attendance: ${attendanceDate.toIso8601String()}');
        print('Start: ${_startDate!.toIso8601String()}');
        print('End: ${_endDate!.toIso8601String()}');
        print('After start: $afterStart, Before end: $beforeEnd, Passes: $passesDateFilter');
        
      } else if (_startDate != null) {
        // Only start date is set - show all attendance from start date onwards
        passesDateFilter = attendance.timestamp.isAfter(_startDate!) || attendance.timestamp.isAtSameMomentAs(_startDate!);
      } else if (_endDate != null) {
        // Only end date is set - show all attendance up to end date
        passesDateFilter = attendance.timestamp.isBefore(_endDate!) || attendance.timestamp.isAtSameMomentAs(_endDate!);
      }
      // If no date filters are set, passesDateFilter remains true

      return passesUserFilter && passesDateFilter;
    }).toList();
    
    // Sort by newest first
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Debug print (remove in production)
    print('Total attendance: ${_attendanceList.length}');
    print('Filtered attendance: ${filtered.length}');
    print('Start date: $_startDate');
    print('End date: $_endDate');
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        backgroundColor: const Color(0xFF001F54),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Ekspor Riwayat Absensi'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final filteredAttendance = _filterAttendance();
                        if (filteredAttendance.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tidak ada data untuk diekspor')),
                          );
                          return;
                        }
                        _exportToExcel(filteredAttendance, 'filtered');
                        Navigator.pop(context);
                      },
                      child: const Text('Data Terfilter'),
                    ),
                    if (_selectedUser != 'All')
                      ElevatedButton(
                        onPressed: () {
                          final userAttendance = _attendanceList.where((a) => a.uid == _selectedUser).toList();
                          if (userAttendance.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tidak ada data untuk user ini')),
                            );
                            return;
                          }
                          _exportToExcel(userAttendance, 'user_${_selectedUser}');
                          Navigator.pop(context);
                        },
                        child: const Text('Semua Data User Ini'),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        if (_attendanceList.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tidak ada data untuk diekspor')),
                          );
                          return;
                        }
                        _exportToExcel(_attendanceList, 'semua');
                        Navigator.pop(context);
                      },
                      child: const Text('Semua Data'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF001F54),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedUser,
                            decoration: const InputDecoration(
                              labelText: 'Filter User',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(value: 'All', child: Text('Semua Karyawan')),
                              ..._users.map((user) => DropdownMenuItem(
                                    value: user['uid'],
                                    child: Text(user['nama'] ?? 'Unknown'),
                                  )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedUser = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Tanggal Mulai',
                                    border: const OutlineInputBorder(),
                                    hintText: _startDate == null
                                        ? 'Pilih tanggal mulai'
                                        : DateFormat('dd MMMM yyyy').format(_startDate!),
                                    suffixIcon: IconButton(
                                      icon: Icon(_startDate == null ? Icons.calendar_today : Icons.clear),
                                      onPressed: () {
                                        if (_startDate == null) {
                                          _selectDate(context, true);
                                        } else {
                                          setState(() {
                                            _startDate = null;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  onTap: () => _selectDate(context, true),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Tanggal Selesai',
                                    border: const OutlineInputBorder(),
                                    hintText: _endDate == null
                                        ? 'Pilih tanggal selesai'
                                        : DateFormat('dd MMMM yyyy').format(_endDate!),
                                    suffixIcon: IconButton(
                                      icon: Icon(_endDate == null ? Icons.calendar_today : Icons.clear),
                                      onPressed: () {
                                        if (_endDate == null) {
                                          _selectDate(context, false);
                                        } else {
                                          setState(() {
                                            _endDate = null;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  onTap: () => _selectDate(context, false),
                                ),
                              ),
                            ],
                          ),
                          if (_startDate != null || _endDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: _clearDateFilters,
                                    icon: const Icon(Icons.clear_all),
                                    label: const Text('Hapus Filter Tanggal'),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Data: ${_filterAttendance().length} item',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _attendanceList.isEmpty
                          ? const Center(child: Text('Tidak ada data absensi'))
                          : Builder(
                              builder: (context) {
                                final filteredAttendance = _filterAttendance();
                                if (filteredAttendance.isEmpty) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Tidak ada data untuk filter ini',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: filteredAttendance.length,
                                  itemBuilder: (context, index) {
                                    final attendance = filteredAttendance[index];
                                    final user = _users.firstWhere(
                                      (u) => u['uid'] == attendance.uid,
                                      orElse: () => {'nama': 'Unknown'},
                                    );
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16.0),
                                      elevation: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    user['nama'] ?? 'Unknown',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: attendance.type == 'Masuk' ? Colors.green.shade100 : Colors.orange.shade100,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    attendance.type,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: attendance.type == 'Masuk' ? Colors.green.shade800 : Colors.orange.shade800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat('dd MMMM yyyy, HH:mm').format(attendance.timestamp),
                                                  style: const TextStyle(color: Colors.grey),
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
                    ),
                  ],
                ),
    );
  }
}