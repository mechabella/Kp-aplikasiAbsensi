import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:location/location.dart' as loc;
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:geocoding/geocoding.dart';
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
  loc.LocationData? _locationData;
  String? _address;
  bool _isLocationLoading = true;
  String _workStatus = 'Work From Office';
  DateTime? _capturedTime;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getLocation();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }
      _cameraController = CameraController(
        frontCamera ?? _cameras![0],
        ResolutionPreset.high,
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

    loc.Location location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    try {
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _isLocationLoading = false;
            _address = 'Layanan lokasi tidak diaktifkan';
          });
          return;
        }
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          setState(() {
            _isLocationLoading = false;
            _address = 'Izin lokasi ditolak';
          });
          return;
        }
      }

      _locationData = await location.getLocation();
      
      if (_locationData != null && 
          _locationData!.latitude != null && 
          _locationData!.longitude != null) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            _locationData!.latitude!,
            _locationData!.longitude!,
          );
          
          if (placemarks.isNotEmpty) {
            Placemark placemark = placemarks[0];
            _address = [
              placemark.street,
              placemark.subLocality,
              placemark.locality,
              placemark.postalCode,
              placemark.country
            ].where((e) => e != null && e.isNotEmpty).join(', ');
          } else {
            _address = 'Alamat tidak tersedia';
          }
        } catch (e) {
          _address = 'Gagal mengambil alamat: ${e.toString()}';
        }
      } else {
        _address = 'Data lokasi tidak lengkap';
      }
    } catch (e) {
      _address = 'Error: ${e.toString()}';
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  Future<XFile> _processImage(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception('Gagal mendekode gambar');
      }

      // Flip the image horizontally for selfie camera
      img.Image processedImage = img.flipHorizontal(originalImage);

      // Get current time or use captured time
      final timeString = _capturedTime != null
          ? DateFormat('dd MMM yyyy - HH:mm:ss').format(_capturedTime!)
          : DateFormat('dd MMM yyyy - HH:mm:ss').format(DateTime.now());

      // Get the current address
      final locationString = _address ?? 'Lokasi: Tidak tersedia';

      // Calculate text sizes for proper background rectangles
      const int fontSize = 16;
      final int timeWidth = timeString.length * fontSize;
      final int addressWidth = locationString.length * (fontSize - 4);
      
      // Draw semi-transparent background for time
      img.fillRect(
        processedImage,
        x1: 10,
        y1: 10,
        x2: timeWidth < 250 ? 250 : timeWidth + 30,
        y2: 40,
        color: img.ColorRgba8(0, 0, 0, 180), // Black with 70% opacity
      );
      
      // Draw time text
      img.drawString(
        processedImage,
        timeString,
        font: img.arial24, // Menggunakan font yang valid
        x: 20,
        y: 15,
        color: img.ColorRgb8(255, 255, 255), // White
      );
      
      // Draw semi-transparent background for address
      // Split address into multiple lines if too long
      final List<String> addressLines = [];
      if (locationString.length > 50) {
        // Simple text wrapping
        int start = 0;
        while (start < locationString.length) {
          int end = start + 50;
          if (end > locationString.length) end = locationString.length;
          // Try to break at a comma or space
          if (end < locationString.length) {
            int breakPoint = locationString.lastIndexOf(',', end);
            if (breakPoint > start && breakPoint < end) {
              end = breakPoint + 1;
            } else {
              breakPoint = locationString.lastIndexOf(' ', end);
              if (breakPoint > start) end = breakPoint;
            }
          }
          addressLines.add(locationString.substring(start, end));
          start = end;
        }
      } else {
        addressLines.add(locationString);
      }
      
      final int addressHeight = addressLines.length * 25 + 10;
      
      img.fillRect(
        processedImage,
        x1: 10,
        y1: processedImage.height - addressHeight - 10,
        x2: addressWidth < 250 ? 350 : addressWidth + 30,
        y2: processedImage.height - 10,
        color: img.ColorRgba8(0, 0, 0, 180), // Black with 70% opacity
      );
      
      // Draw address text (possibly multi-line)
      for (int i = 0; i < addressLines.length; i++) {
        img.drawString(
          processedImage,
          addressLines[i],
          font: img.arial14, // Menggunakan font yang valid
          x: 20,
          y: processedImage.height - addressHeight - 5 + (i * 25),
          color: img.ColorRgb8(255, 255, 255), // White
        );
      }
      
      // Also add work status to the image
      final String statusText = "Status: $_workStatus";
      img.fillRect(
        processedImage,
        x1: 10,
        y1: 50,
        x2: 250,
        y2: 80, 
        color: img.ColorRgba8(0, 0, 0, 180), // Black with 70% opacity
      );
      
      img.drawString(
        processedImage,
        statusText,
        font: img.arial14, // Menggunakan font yang valid
        x: 20,
        y: 55,
        color: img.ColorRgb8(255, 255, 255), // White
      );

      // Save the processed image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${tempDir.path}/processed_$timestamp.jpg';
      
      File(tempPath).writeAsBytesSync(img.encodeJpg(processedImage, quality: 90));
      
      return XFile(tempPath);
    } catch (e) {
      print('Error processing image: $e');
      // If image processing fails, return the original image
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses gambar: $e')),
      );
      return image;
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamera tidak tersedia')),
      );
      return;
    }

    try {
      // Save the time when the photo is taken
      _capturedTime = DateTime.now();
      
      final image = await _cameraController!.takePicture();
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final processedImage = await _processImage(image);
      
      // Hide loading indicator
      Navigator.of(context).pop();
      
      setState(() {
        _imageFile = processedImage;
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            Container(
                              height: 400,
                              width: double.infinity,
                              child: _imageFile != null
                                  ? Image.file(
                                      File(_imageFile!.path),
                                      fit: BoxFit.cover,
                                    )
                                  : (_cameraController != null && _cameraController!.value.isInitialized)
                                      ? CameraPreview(_cameraController!)
                                      : const Center(child: Text('Kamera tidak tersedia')),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ElevatedButton.icon(
                                  onPressed: _imageFile != null
                                      ? () {
                                          setState(() {
                                            _imageFile = null;
                                            _capturedTime = null; // Reset time when retaking
                                          });
                                        }
                                      : _takePicture,
                                  icon: Icon(
                                    _imageFile != null ? Icons.refresh : Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    _imageFile != null ? 'Retake Photo' : 'Take Photo',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF001F54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    minimumSize: const Size(double.infinity, 48),
                                  ),
                                ),
                              ),
                            ),
                            if (_cameraController != null && _cameraController!.value.isInitialized && _imageFile == null)
                              Positioned(
                                left: 16,
                                top: 16,
                                child: StreamBuilder(
                                  stream: Stream.periodic(const Duration(seconds: 1)),
                                  builder: (context, snapshot) {
                                    final currentTime = DateTime.now();
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            DateFormat('HH:mm:ss').format(currentTime),
                                            style: const TextStyle(color: Colors.white, fontSize: 14),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 250,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _isLocationLoading
                                                ? 'Mengambil alamat...'
                                                : _address ?? 'Alamat tidak tersedia',
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                              borderSide: BorderSide(color: Colors.grey.shade300),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isLocationLoading
                                      ? 'Mengambil alamat...'
                                      : _address ?? 'Alamat tidak tersedia',
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_imageFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Harap ambil foto terlebih dahulu')),
                  );
                  return;
                }

                if (_locationData == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lokasi tidak tersedia')),
                  );
                  return;
                }

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