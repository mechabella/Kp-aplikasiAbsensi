import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:universal_io/io.dart' show Platform;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/auth_service.dart';
import '../models/attendance.dart';
import '../models/permission.dart';

class HistoryAttendanceScreen extends StatefulWidget {
  const HistoryAttendanceScreen({super.key});

  @override
  _HistoryAttendanceScreenState createState() =>
      _HistoryAttendanceScreenState();
}

class _HistoryAttendanceScreenState extends State<HistoryAttendanceScreen> {
  List<Attendance> _attendanceList = [];
  List<Permission> _permissionList = [];
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
      final permissions = await authService.getAllPermissions();
      setState(() {
        _users = users;
        _attendanceList = attendance;
        _permissionList = permissions;
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
          _startDate = DateTime(value.year, value.month, value.day, 0, 0, 0);
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = DateTime(value.year, value.month, value.day, 23, 59, 59);
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Tanggal selesai harus setelah tanggal mulai')),
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

  // Method untuk request storage permission yang lebih komprehensif
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Untuk Android 11+ (API 30+)
      if (await perm.Permission.manageExternalStorage.isGranted) {
        return true;
      }
      
      // Request manage external storage permission
      final status = await perm.Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      }
      
      // Fallback ke storage permission biasa
      final storageStatus = await perm.Permission.storage.request();
      return storageStatus.isGranted;
    }
    
    return true; // iOS tidak memerlukan permission khusus
  }

  // Method tambahan untuk memindahkan file ke Download folder
  Future<void> _moveToDownloadFolder(File sourceFile, String fileName) async {
    try {
      // Minta permission storage
      bool hasPermission = await _requestStoragePermission();
      
      if (hasPermission) {
        // Coba beberapa lokasi Download yang mungkin
        List<String> possibleDownloadPaths = [
          '/storage/emulated/0/Download',
          '/sdcard/Download',
          '/storage/sdcard0/Download',
        ];
        
        for (String downloadPath in possibleDownloadPaths) {
          try {
            final Directory downloadDir = Directory(downloadPath);
            if (await downloadDir.exists()) {
              final File targetFile = File('$downloadPath/$fileName');
              
              // Copy file ke Download folder
              await sourceFile.copy(targetFile.path);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('File berhasil dipindah ke: ${targetFile.path}')),
              );
              return;
            }
          } catch (e) {
            print('Failed to copy to $downloadPath: $e');
            continue;
          }
        }
      }
      
      // Jika gagal, bagikan file
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat memindah ke folder Download. File tetap tersimpan di aplikasi.'),
        ),
      );
      
    } catch (e) {
      print('Error moving file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memindahkan file')),
      );
    }
  }

  Future<void> _exportToExcel(List<dynamic> combinedList, String type) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Riwayat Absensi & Izin'];

      // Header row
      sheet.appendRow([
        TextCellValue('Nama Karyawan'),
        TextCellValue('Tanggal'),
        TextCellValue('Status'),
        TextCellValue('Catatan'),
      ]);

      // Data rows
      for (var item in combinedList) {
        final user = _users.firstWhere(
            (u) => u['uid'] == (item is Attendance ? item.uid : item.uid),
            orElse: () => {'nama': 'Unknown'});
        String status = '';
        String notes = '';

        if (item is Attendance) {
          status = item.type == 'clock_in' ? 'Masuk' : 'Keluar';
          notes = _getAttendanceNotes(item.timestamp, item.type);
        } else if (item is Permission) {
          status = 'Izin (${item.type})';
          notes = item.status;
        }

        sheet.appendRow([
          TextCellValue(user['nama'] ?? 'Unknown'),
          TextCellValue(item is Attendance
              ? DateFormat('dd MMMM yyyy, HH:mm').format(item.timestamp)
              : '${DateFormat('dd MMMM yyyy').format(item.fromDate)} - ${DateFormat('dd MMMM yyyy').format(item.toDate)}'),
          TextCellValue(status),
          TextCellValue(notes),
        ]);
      }

      Uint8List? fileBytes = excel.save() != null ? Uint8List.fromList(excel.save()!) : null;
      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghasilkan file Excel')),
        );
        return;
      }

      final baseFileName = 'riwayat_absensi_izin_${type}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';
      String fileName = '$baseFileName.xlsx';

      try {
        // SOLUSI 1: Gunakan SAF (Storage Access Framework) untuk Android 11+
        if (Platform.isAndroid) {
          // Coba simpan di direktori app terlebih dahulu
          final Directory? appDir = await getExternalStorageDirectory();
          if (appDir != null) {
            final Directory downloadDir = Directory('${appDir.path}/Downloads');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            
            // Pastikan nama file unik
            File file = File('${downloadDir.path}/$fileName');
            int suffix = 1;
            while (await file.exists()) {
              fileName = '${baseFileName}_$suffix.xlsx';
              file = File('${downloadDir.path}/$fileName');
              suffix++;
            }

            await file.writeAsBytes(fileBytes);

            // Tampilkan dialog pilihan
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('File Berhasil Disimpan'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('File disimpan di:\n${file.path}'),
                      const SizedBox(height: 16),
                      const Text('Pilih tindakan:'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Bagikan file menggunakan share_plus
                        Share.shareXFiles([XFile(file.path)], text: 'Riwayat Absensi & Izin');
                      },
                      child: const Text('Bagikan'),
                    ),
                    if (Platform.isAndroid)
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          // Coba pindahkan ke Download folder menggunakan file manager
                          await _moveToDownloadFolder(file, fileName);
                        },
                        child: const Text('Pindah ke Download'),
                      ),
                  ],
                ),
              );
            }

            return;
          }
        }

        // SOLUSI 2: Untuk iOS atau fallback
        final Directory? documentsDir = await getApplicationDocumentsDirectory();
        if (documentsDir != null) {
          File file = File('${documentsDir.path}/$fileName');
          int suffix = 1;
          while (await file.exists()) {
            fileName = '${baseFileName}_$suffix.xlsx';
            file = File('${documentsDir.path}/$fileName');
            suffix++;
          }

          await file.writeAsBytes(fileBytes);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File disimpan di: ${file.path}'),
                action: SnackBarAction(
                  label: 'Bagikan',
                  onPressed: () {
                    Share.shareXFiles([XFile(file.path)], text: 'Riwayat Absensi & Izin');
                  },
                ),
              ),
            );
          }
        }

      } catch (e) {
        // SOLUSI 3: Jika gagal menyimpan, langsung bagikan file
        print('Error saving file: $e');
        
        // Simpan di temporary directory dan bagikan
        final Directory tempDir = await getTemporaryDirectory();
        final File tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(fileBytes);
        
        await Share.shareXFiles([XFile(tempFile.path)], text: 'Riwayat Absensi & Izin');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File dibagikan karena tidak dapat menyimpan ke storage publik'),
            ),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal meneksport file: $e')),
        );
      }
      print('Export error details: $e');
    }
  }

  String _getAttendanceNotes(DateTime timestamp, String type) {
    final officeStart =
        DateTime(timestamp.year, timestamp.month, timestamp.day, 8, 0, 0);
    final officeEnd =
        DateTime(timestamp.year, timestamp.month, timestamp.day, 17, 0, 0);

    if (type == 'clock_in' && timestamp.isAfter(officeStart)) {
      return 'Terlambat';
    } else if (type == 'clock_out' && timestamp.isBefore(officeEnd)) {
      return 'Pulang Cepat';
    }
    return 'Tepat Waktu';
  }

  List<dynamic> _filterCombinedData() {
    List<dynamic> combined = [..._attendanceList, ..._permissionList];
    return combined.where((item) {
      bool passesUserFilter = _selectedUser == 'All' ||
          (item is Attendance ? item.uid : item.uid) == _selectedUser;

      bool passesDateFilter = true;
      DateTime itemDate = item is Attendance ? item.timestamp : item.fromDate;

      if (_startDate != null && _endDate != null) {
        bool afterStart = itemDate.isAfter(_startDate!) ||
            itemDate.isAtSameMomentAs(_startDate!);
        bool beforeEnd = itemDate.isBefore(_endDate!) ||
            itemDate.isAtSameMomentAs(_endDate!);
        passesDateFilter = afterStart && beforeEnd;
      } else if (_startDate != null) {
        passesDateFilter = itemDate.isAfter(_startDate!) ||
            itemDate.isAtSameMomentAs(_startDate!);
      } else if (_endDate != null) {
        passesDateFilter = itemDate.isBefore(_endDate!) ||
            itemDate.isAtSameMomentAs(_endDate!);
      }

      return passesUserFilter && passesDateFilter;
    }).toList()
      ..sort((a, b) => (b is Attendance ? b.timestamp : b.fromDate)
          .compareTo(a is Attendance ? a.timestamp : a.fromDate));
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
                title: const Text('Ekspor Riwayat Absensi & Izin'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final combinedData = _filterCombinedData();
                          if (combinedData.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Tidak ada data untuk diekspor')),
                            );
                            return;
                          }
                          _exportToExcel(combinedData, 'filtered');
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF001F54),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Data Terfilter'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedUser != 'All')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final userData = [
                              ..._attendanceList
                                  .where((a) => a.uid == _selectedUser)
                                  .toList(),
                              ..._permissionList
                                  .where((p) => p.uid == _selectedUser)
                                  .toList(),
                            ];
                            if (userData.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Tidak ada data untuk user ini')),
                              );
                              return;
                            }
                            _exportToExcel(userData, 'user_${_selectedUser}');
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Semua Data User Ini'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final combinedData = [
                            ..._attendanceList,
                            ..._permissionList
                          ];
                          if (combinedData.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Tidak ada data untuk diekspor')),
                            );
                            return;
                          }
                          _exportToExcel(combinedData, 'semua');
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Semua Data'),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ],
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
                              const DropdownMenuItem(
                                  value: 'All', child: Text('Semua Karyawan')),
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
                                        : DateFormat('dd MMMM yyyy')
                                            .format(_startDate!),
                                    suffixIcon: IconButton(
                                      icon: Icon(_startDate == null
                                          ? Icons.calendar_today
                                          : Icons.clear),
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
                                        : DateFormat('dd MMMM yyyy')
                                            .format(_endDate!),
                                    suffixIcon: IconButton(
                                      icon: Icon(_endDate == null
                                          ? Icons.calendar_today
                                          : Icons.clear),
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
                                    'Data: ${_filterCombinedData().length} item',
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
                      child: _attendanceList.isEmpty && _permissionList.isEmpty
                          ? const Center(
                              child: Text('Tidak ada data absensi atau izin'))
                          : Builder(
                              builder: (context) {
                                final combinedData = _filterCombinedData();
                                if (combinedData.isEmpty) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                  itemCount: combinedData.length,
                                  itemBuilder: (context, index) {
                                    final item = combinedData[index];
                                    final user = _users.firstWhere(
                                      (u) =>
                                          u['uid'] ==
                                          (item is Attendance
                                              ? item.uid
                                              : item.uid),
                                      orElse: () => {'nama': 'Unknown'},
                                    );
                                    return Card(
                                      margin:
                                          const EdgeInsets.only(bottom: 16.0),
                                      elevation: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    user['nama'] ?? 'Unknown',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: item is Attendance
                                                        ? (item.type ==
                                                                'clock_in'
                                                            ? Colors
                                                                .green.shade100
                                                            : Colors.orange
                                                                .shade100)
                                                        : Colors.blue.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    item is Attendance
                                                        ? item.type == 'clock_in'
                                                            ? 'Masuk'
                                                            : 'Keluar'
                                                        : 'Izin (${item.type})',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          item is Attendance
                                                              ? (item.type ==
                                                                      'clock_in'
                                                                  ? Colors.green
                                                                      .shade800
                                                                  : Colors
                                                                      .orange
                                                                      .shade800)
                                                              : Colors.blue
                                                                  .shade800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                  item is Attendance
                                                      ? DateFormat(
                                                              'dd MMMM yyyy, HH:mm')
                                                          .format(
                                                              item.timestamp)
                                                      : '${DateFormat('dd MMMM yyyy').format(item.fromDate)} - ${DateFormat('dd MMMM yyyy').format(item.toDate)}',
                                                  style: const TextStyle(
                                                      color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                            if (item is Attendance)
                                              Text(
                                                'Catatan: ${_getAttendanceNotes(item.timestamp, item.type)}',
                                                style: const TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            if (item is Permission)
                                              Text(
                                                'Status: ${item.status}',
                                                style: TextStyle(
                                                  color:
                                                      item.status == 'Approved'
                                                          ? Colors.green
                                                          : item.status ==
                                                                  'Rejected'
                                                              ? Colors.red
                                                              : Colors.orange,
                                                ),
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