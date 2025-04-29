import 'dart:io';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DriveHelper {
  static const String folderId = 'YOUR_GOOGLE_DRIVE_FOLDER_ID'; // Ganti dengan ID folder kamu

  static Future<String?> uploadToGoogleDrive(File file, {required String assetCredentialsPath}) async {
    try {
      final credentials = await DefaultAssetBundle.of(PlatformAssetBundle()).loadString(assetCredentialsPath);
      final serviceAccountCredentials = ServiceAccountCredentials.fromJson(credentials);
      final scopes = [drive.DriveApi.driveFileScope];
      final authClient = await clientViaServiceAccount(serviceAccountCredentials, scopes);

      final driveApi = drive.DriveApi(authClient);

      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(tempDir.path, path.basename(file.path));
      await file.copy(tempPath);

      final driveFile = drive.File();
      driveFile.name = path.basename(tempPath);
      driveFile.parents = [folderId];

      final stream = http.ByteStream(Stream.castFrom(File(tempPath).openRead()));
      final media = drive.Media(stream, await File(tempPath).length());
      final uploadedFile = await driveApi.files.create(driveFile, uploadMedia: media);

      final fileId = uploadedFile.id;
      await driveApi.permissions.create(
        drive.Permission()..role = 'reader'..type = 'anyone',
        fileId!,
      );
      final fileDetails = await driveApi.files.get(fileId, $fields: 'webViewLink') as drive.File;
      final fileUrl = fileDetails.webViewLink;

      authClient.close();
      return fileUrl;
    } catch (e) {
      print('Error uploading to Google Drive: $e');
      return null;
    }
  }
}