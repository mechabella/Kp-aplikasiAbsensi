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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          if (_startDate != null && picked.isBefore(_startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tanggal selesai harus setelah tanggal mulai')),
            );
            return;
          }
          _endDate = picked;
        }
      });
    }
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
    return _attendanceList.where((attendance) {
      bool passesUserFilter = _selectedUser == 'All' || attendance.uid == _selectedUser;
      bool passesDateFilter = true;
      if (_startDate != null) {
        passesDateFilter = attendance.timestamp.isAfter(_startDate!.subtract(const Duration(days: 1)));
      }
      if (_endDate != null) {
        passesDateFilter = passesDateFilter && attendance.timestamp.isBefore(_endDate!.add(const Duration(days: 1)));
      }
      return passesUserFilter && passesDateFilter;
    }).toList();
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
                                        ? 'Pilih tanggal'
                                        : DateFormat('dd MMMM yyyy').format(_startDate!),
                                    suffixIcon: const Icon(Icons.calendar_today),
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
                                        ? 'Pilih tanggal'
                                        : DateFormat('dd MMMM yyyy').format(_endDate!),
                                    suffixIcon: const Icon(Icons.calendar_today),
                                  ),
                                  onTap: () => _selectDate(context, false),
                                ),
                              ),
                            ],
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
                                  return const Center(child: Text('Tidak ada data untuk filter ini'));
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
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Nama: ${user['nama'] ?? 'Unknown'}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Tanggal: ${DateFormat('dd MMMM yyyy, HH:mm').format(attendance.timestamp)}',
                                            ),
                                            Text('Status: ${attendance.type}'),
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