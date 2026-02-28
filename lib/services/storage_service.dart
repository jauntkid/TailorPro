import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Service for uploading images to Firebase Storage.
/// Converts local file paths to cloud download URLs.
class StorageService {
  StorageService._();
  static final instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a single image file and return the download URL.
  /// [localPath] is the local file path.
  /// [folder] is the Storage folder (e.g., 'orders/ORD-00005').
  Future<String> uploadImage(String localPath,
      {String folder = 'images'}) async {
    final file = File(localPath);
    if (!file.existsSync()) return localPath; // Already a URL or missing

    // Skip if already a URL (http/https)
    if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
      return localPath;
    }

    final ext =
        p.extension(localPath).isNotEmpty ? p.extension(localPath) : '.jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final ref = _storage.ref().child('$folder/$fileName');

    try {
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/${ext.replaceAll('.', '')}'),
      );
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Storage upload failed: $e');
      return localPath; // Fallback to local path
    }
  }

  /// Upload multiple images and return list of download URLs.
  Future<List<String>> uploadImages(List<String> localPaths,
      {String folder = 'images'}) async {
    if (localPaths.isEmpty) return [];

    final futures = localPaths.map((path) => uploadImage(path, folder: folder));
    return Future.wait(futures);
  }

  /// Delete an image from Storage by its URL.
  Future<void> deleteImage(String url) async {
    if (!url.startsWith('https://firebasestorage.googleapis.com')) return;
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      debugPrint('Storage delete failed: $e');
    }
  }
}
