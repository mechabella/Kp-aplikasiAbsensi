import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_services.dart';
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
  String _workStatus = 'Work From Office'; // Default status kerja

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getLocation();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![1], // Kamera depan (selfie)
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
      setState(() {});
    }
  }

  Future<void> _getLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _locationData = await location.getLocation();
    setState(() {});
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
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: const Color(0xFF001F54),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Waktu dan tanggal saat ini
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(DateTime.now()),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    DateFormat('HH:mm').format(DateTime.now()),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Preview kamera atau foto yang diambil
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: _imageFile != null
                  ? Image.file(
                      File(_imageFile!.path),
                      fit: BoxFit.cover,
                    )
                  : (_cameraController != null && _cameraController!.value.isInitialized)
                      ? CameraPreview(_cameraController!)
                      : const Center(child: Text('Kamera tidak tersedia')),
            ),
            // Tombol Reset Photo
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _imageFile = null;
                    });
                  },
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  label: const Text('Reset Photo', style: TextStyle(color: Colors.blue)),
                ),
              ),
            // Status kerja (Work From Home / Work From Office)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'I will subject',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  DropdownButton<String>(
                    value: _workStatus,
                    items: const [
                      DropdownMenuItem(value: 'Work From Office', child: Text('Work From Office')),
                      DropdownMenuItem(value: 'Work From Home', child: Text('Work From Home')),
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
            // Lokasi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationData != null
                          ? 'Lokasi: ${_locationData!.latitude}, ${_locationData!.longitude}'
                          : 'Mendapatkan lokasi...',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            // Tombol Clock In
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _imageFile == null
                    ? _takePicture
                    : () {
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
                child: Text(_imageFile == null ? 'Capture Photo' : 'Clock In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}