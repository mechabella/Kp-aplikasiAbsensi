import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DriveHelper {
  // Folder ID untuk surat izin
  static const String permissionFolderId =
      '1qUgxFFyRJ-Y-rw1PHNQCNfBktFaoWKW0'; // Ganti dengan Folder ID untuk surat izin
  // Folder ID untuk foto absensi
  static const String attendanceFolderId =
      '1z1N2gOHbDs7Huaj4N5Nj3Ht5VfwKCqYw'; // Ganti dengan Folder ID untuk foto absensi

  static Future<String?> uploadToGoogleDrive(
    File file, {
    required String assetCredentialsPath,
    String? targetFolderId,
  }) async {
    try {
      final credentials = await rootBundle.loadString(assetCredentialsPath);
      final serviceAccountCredentials =
          ServiceAccountCredentials.fromJson(credentials);
      final scopes = [drive.DriveApi.driveFileScope];
      final authClient =
          await clientViaServiceAccount(serviceAccountCredentials, scopes);

      final driveApi = drive.DriveApi(authClient);

      // Ubah nama file agar ekstensinya .png
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = path.join(
          tempDir.path, 'attendance_$timestamp.png'); // Pastikan ekstensi .png
      await file.copy(tempPath);

      final driveFile = drive.File();
      driveFile.name =
          path.basename(tempPath); // Gunakan nama file dengan ekstensi .png
      driveFile.mimeType = 'image/png'; // Tentukan MIME type secara eksplisit
      driveFile.parents = [targetFolderId ?? permissionFolderId];

      final stream =
          http.ByteStream(Stream.castFrom(File(tempPath).openRead()));
      final media = drive.Media(stream, await File(tempPath).length());
      final uploadedFile =
          await driveApi.files.create(driveFile, uploadMedia: media);

      final fileId = uploadedFile.id;
      await driveApi.permissions.create(
        drive.Permission()
          ..role = 'reader'
          ..type = 'anyone',
        fileId!,
      );
      final fileDetails = await driveApi.files
          .get(fileId, $fields: 'webViewLink') as drive.File;
      final fileUrl = fileDetails.webViewLink;

      authClient.close();
      return fileUrl;
    } catch (e) {
      print('Error uploading to Google Drive: $e');
      return null;
    }
  }
}
