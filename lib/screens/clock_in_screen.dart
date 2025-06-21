import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/foundation.dart' show kIsWeb;
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
  double? _imageAspectRatio;

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

    if (kIsWeb) {
      setState(() {
        _isLocationLoading = false;
        _address = 'Fitur lokasi tidak tersedia di web';
      });
      return;
    }

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
      print('Memulai pemrosesan gambar...');

      // Langkah 1: Dekode gambar menggunakan package image
      final bytes = await image.readAsBytes();
      print('Berhasil membaca bytes gambar: ${bytes.length} bytes');

      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        throw Exception('Gagal mendekode gambar');
      }
      print(
          'Berhasil mendekode gambar: ${originalImage.width}x${originalImage.height}');

      // Langkah 2: Balik gambar secara horizontal
      img.Image flippedImage = img.flipHorizontal(originalImage);
      print('Berhasil membalik gambar secara horizontal');

      // Langkah 3: Konversi gambar ke format ui.Image untuk digunakan dengan Canvas
      final uiBytes = img.encodePng(flippedImage);
      final ui.Image uiImage = await decodeImageFromList(uiBytes);
      print('Berhasil mengkonversi ke ui.Image');

      // Langkah 4: Siapkan teks yang akan ditambahkan
      final timeString = _capturedTime != null
          ? DateFormat('dd MMM yyyy - HH:mm:ss').format(_capturedTime!)
          : DateFormat('dd MMM yyyy - HH:mm:ss').format(DateTime.now());
      final locationString = _address ?? 'Lokasi: Tidak tersedia';
      final statusText = "Status: $_workStatus";
      print('Waktu: $timeString, Alamat: $locationString, Status: $statusText');

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      canvas.drawImage(uiImage, Offset.zero, ui.Paint());

      TextPainter textPainter(String text, double fontSize, Color color,
          {int? maxLines}) {
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
          maxLines: maxLines,
        );
        painter.layout(
            maxWidth:
                uiImage.width.toDouble() - 40); // Beri padding 20 di kedua sisi
        return painter;
      }

      // Gambar latar belakang semi-transparan dan teks waktu
      final timePainter = textPainter(timeString, 24, Colors.white);
      final timeBackground = ui.Paint()..color = Colors.black.withOpacity(0.7);
      canvas.drawRect(
        ui.Rect.fromLTWH(
          10,
          10,
          timePainter.width + 20,
          timePainter.height + 10,
        ),
        timeBackground,
      );
      timePainter.paint(canvas, const Offset(20, 15));
      print('Berhasil menambahkan teks waktu');

      // Gambar latar belakang dan teks status kerja
      final statusPainter = textPainter(statusText, 16, Colors.white);
      final statusBackground = ui.Paint()
        ..color = Colors.black.withOpacity(0.7);
      canvas.drawRect(
        ui.Rect.fromLTWH(
          10,
          60,
          statusPainter.width + 20,
          statusPainter.height + 10,
        ),
        statusBackground,
      );
      statusPainter.paint(canvas, const Offset(20, 65));
      print('Berhasil menambahkan teks status kerja');

      // Gambar latar belakang dan teks alamat (dengan text wrapping)
      final addressPainter =
          textPainter(locationString, 16, Colors.white, maxLines: 2);
      final addressBackground = ui.Paint()
        ..color = Colors.black.withOpacity(0.7);
      canvas.drawRect(
        ui.Rect.fromLTWH(
          10,
          uiImage.height.toDouble() - addressPainter.height - 20,
          addressPainter.width + 20,
          addressPainter.height + 10,
        ),
        addressBackground,
      );
      addressPainter.paint(canvas,
          Offset(20, uiImage.height.toDouble() - addressPainter.height - 15));
      print('Berhasil menambahkan teks alamat');

      // Langkah 6: Simpan hasil Canvas ke file
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(uiImage.width, uiImage.height);
      final byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal mengkonversi gambar ke byte data');
      }
      final buffer = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${tempDir.path}/processed_$timestamp.png';

      // Simpan file
      final processedFile = File(tempPath);
      await processedFile.writeAsBytes(buffer);
      print('Berhasil menyimpan gambar ke: $tempPath');

      // Verifikasi bahwa file dapat dibaca kembali sebagai gambar
      final verificationImage =
          img.decodeImage(await processedFile.readAsBytes());
      if (verificationImage == null) {
        throw Exception('Gambar yang diproses tidak valid');
      }
      print('Verifikasi berhasil: Gambar dapat dibaca kembali');

      // Simpan aspek rasio untuk tampilan
      setState(() {
        _imageAspectRatio = uiImage.width / uiImage.height;
      });

      return XFile(tempPath);
    } catch (e) {
      print('Error processing image: $e');
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
      Navigator.of(context)
          .pop(); // Pastikan loading indicator ditutup jika ada error
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
                        border:
                            Border.all(color: Colors.blue.shade100, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: _imageAspectRatio != null
                                  ? (MediaQuery.of(context).size.width - 32) /
                                      _imageAspectRatio!
                                  : 400, // 32 adalah padding horizontal total
                              child: _imageFile != null
                                  ? Image.file(
                                      File(_imageFile!.path),
                                      fit: BoxFit.contain,
                                    )
                                  : (_cameraController != null &&
                                          _cameraController!
                                              .value.isInitialized)
                                      ? CameraPreview(_cameraController!)
                                      : const Center(
                                          child: Text('Kamera tidak tersedia')),
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
                                            _capturedTime = null;
                                            _imageAspectRatio = null;
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
                                        ? 'Retake Photo'
                                        : 'Take Photo',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF001F54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                  ),
                                ),
                              ),
                            ),
                            if (_cameraController != null &&
                                _cameraController!.value.isInitialized &&
                                _imageFile == null)
                              Positioned(
                                left: 16,
                                top: 16,
                                child: StreamBuilder(
                                  stream: Stream.periodic(
                                      const Duration(seconds: 1)),
                                  builder: (context, snapshot) {
                                    final currentTime = DateTime.now();
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            DateFormat('HH:mm:ss')
                                                .format(currentTime),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 250,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _isLocationLoading
                                                ? 'Mengambil alamat...'
                                                : _address ??
                                                    'Alamat tidak tersedia',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
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
