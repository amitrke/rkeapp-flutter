import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

const _sizeDimensions = <String, String>{
  's': '200x200',
  'm': '680x680',
  'l': '1920x1080',
};

String _storagePath(String userId, String filename, String size) {
  final lastDot = filename.lastIndexOf('.');
  final base = lastDot != -1 ? filename.substring(0, lastDot) : filename;
  final ext = lastDot != -1 ? filename.substring(lastDot + 1) : '';
  final dimensions = _sizeDimensions[size] ?? _sizeDimensions['m']!;
  return 'users/$userId/images/${base}_$dimensions.$ext';
}

/// Returns a download URL for the image. Accepts either an existing https URL
/// or a raw filename resolved via Firebase Storage.
Future<String> resolveStorageImage(
  String userId,
  String filename, {
  String size = 'm',
}) async {
  if (filename.startsWith('http')) return filename;
  try {
    return await FirebaseStorage.instance
        .ref(_storagePath(userId, filename, size))
        .getDownloadURL();
  } catch (_) {
    return '';
  }
}

/// Resizes [file] to max 680px on the longer side, uploads it to Firebase
/// Storage under `users/[userId]/images/`, and returns the stored filename
/// (the value to persist in Firestore).
Future<String> resizeAndUploadImage(File file, String userId) async {
  final original = p
      .basenameWithoutExtension(file.path)
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w]'), '-')
      .replaceAll(RegExp(r'-+'), '-');
  final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final baseName = '$original-$timestamp';
  final storedName = '$baseName.$ext';

  final bytes = await file.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception('Could not decode image');

  final resized = decoded.width > decoded.height
      ? img.copyResize(decoded, width: 680)
      : img.copyResize(decoded, height: 680);
  final resizedBytes = img.encodeJpg(resized, quality: 85);

  await FirebaseStorage.instance
      .ref('users/$userId/images/${baseName}_680x680.$ext')
      .putData(resizedBytes, SettableMetadata(contentType: 'image/jpeg'));

  return storedName;
}
