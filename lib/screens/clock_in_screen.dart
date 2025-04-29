import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'clock_in_confirmation_screen.dart';

class ClockInScreen extends StatefulWidget {
  const ClockInScreen({super.key});

  @override
  _ClockInScreenState createState() => _ClockInScreenState();
}

class _ClockInScreenState extends State<ClockInScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  XFile? _imageFile;
  LocationData? _locationData;
  bool _isLocationLoading = true;
  String _workStatus = 'Work From Office';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getLocation();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      // Cari kamera depan
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }
      // Jika tidak ada kamera depan, gunakan kamera pertama
      _cameraController = CameraController(
        frontCamera ?? _cameras![0],
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }
    }

    _locationData = await location.getLocation();
    setState(() {
      _isLocationLoading = false;
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamera tidak tersedia')),
      );
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _imageFile = image;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          DateFormat('dd MMM yyyy').format(DateTime.now()),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Preview kamera atau foto yang diambil
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.blue.shade100, width: 2),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10)),
                            child: Container(
                              height: 300,
                              width: double.infinity,
                              child: _imageFile != null
                                  ? Image.file(
                                      File(_imageFile!.path),
                                      fit: BoxFit.cover,
                                    )
                                  : (_cameraController != null &&
                                          _cameraController!
                                              .value.isInitialized)
                                      ? CameraPreview(_cameraController!)
                                      : const Center(
                                          child: Text('Kamera tidak tersedia')),
                            ),
                          ),
                          // Tombol Ambil Gambar / Foto Ulang
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: ElevatedButton.icon(
                              onPressed: _imageFile != null
                                  ? () {
                                      setState(() {
                                        _imageFile = null;
                                      });
                                    }
                                  : _takePicture,
                              icon: Icon(
                                _imageFile != null
                                    ? Icons.refresh
                                    : Icons.camera_alt,
                                color: Colors.white,
                              ),
                              label: Text(
                                _imageFile != null
                                    ? 'Foto Ulang'
                                    : 'Ambil Gambar',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF001F54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                minimumSize: const Size(200, 0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Work Status
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Work Status',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _workStatus,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Work From Office',
                              child: Text('Work From Office'),
                            ),
                            DropdownMenuItem(
                              value: 'Work From Home',
                              child: Text('Work From Home'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _workStatus = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Location
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isLocationLoading
                                      ? 'Mengambil lokasi...'
                                      : _locationData != null
                                          ? '${_locationData!.latitude}, ${_locationData!.longitude}'
                                          : 'Lokasi tidak tersedia',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tombol Clock In selalu di bawah
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_imageFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Harap ambil foto terlebih dahulu')),
                  );
                  return;
                }

                if (_locationData == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lokasi tidak tersedia')),
                  );
                  return;
                }

                // Navigasi ke halaman konfirmasi
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClockInConfirmationScreen(
                      imageFile: _imageFile!,
                      latitude: _locationData!.latitude!,
                      longitude: _locationData!.longitude!,
                      workStatus: _workStatus,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001F54),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clock In', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
