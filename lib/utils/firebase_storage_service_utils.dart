import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _imagePicker = ImagePicker();

  // Upload image from camera/gallery
  static Future<String?> uploadImage({
    required String folder,
    required String fileName,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image == null) return null;

      // Create reference
      final ref = _storage.ref().child('$folder/$fileName');

      // Upload based on platform
      String? downloadUrl;

      if (kIsWeb) {
        // Web platform
        final bytes = await image.readAsBytes();
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else {
        // Mobile/Desktop platforms
        final file = File(image.path);
        final uploadTask = ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload any file type
  static Future<String?> uploadFile({
    required String folder,
    required String fileName,
    List<String>? allowedExtensions,
  }) async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final ref = _storage.ref().child('$folder/$fileName');

      String? downloadUrl;

      if (kIsWeb) {
        // Web platform
        if (file.bytes != null) {
          final uploadTask = ref.putData(
            file.bytes!,
            SettableMetadata(contentType: _getContentType(file.extension)),
          );

          final snapshot = await uploadTask;
          downloadUrl = await snapshot.ref.getDownloadURL();
        }
      } else {
        // Mobile/Desktop platforms
        if (file.path != null) {
          final fileObj = File(file.path!);
          final uploadTask = ref.putFile(
            fileObj,
            SettableMetadata(contentType: _getContentType(file.extension)),
          );

          final snapshot = await uploadTask;
          downloadUrl = await snapshot.ref.getDownloadURL();
        }
      }

      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Upload from bytes (useful for generated content)
  static Future<String?> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref().child('$folder/$fileName');

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: contentType ?? 'application/octet-stream',
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading bytes: $e');
      return null;
    }
  }

  // Upload with progress tracking
  static Future<String?> uploadWithProgress({
    required String folder,
    required String fileName,
    required Function(double) onProgress,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return null;

      final ref = _storage.ref().child('$folder/$fileName');

      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        uploadTask = ref.putData(bytes);
      } else {
        final file = File(image.path);
        uploadTask = ref.putFile(file);
      }

      // Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading with progress: $e');
      return null;
    }
  }

  // Download file
  static Future<Uint8List?> downloadFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      final bytes = await ref.getData();
      return bytes;
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

  // Delete file
  static Future<bool> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // List files in a folder
  static Future<List<String>> listFiles(String folder) async {
    try {
      final ref = _storage.ref().child(folder);
      final result = await ref.listAll();

      final urls = <String>[];
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      print('Error listing files: $e');
      return [];
    }
  }

  // Get file metadata
  static Future<FullMetadata?> getFileMetadata(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('Error getting metadata: $e');
      return null;
    }
  }

  // Helper method to determine content type
  static String _getContentType(String? extension) {
    if (extension == null) return 'application/octet-stream';

    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
