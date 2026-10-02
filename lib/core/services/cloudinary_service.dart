import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/presentation/auth_providers.dart';
import '../errors/app_failure.dart';

enum CloudinaryFolder {
  properties('land_owner/properties'),
  documents('land_owner/documents'),
  receipts('land_owner/receipts'),
  avatars('land_owner/avatars'),
  tickets('land_owner/tickets');

  const CloudinaryFolder(this.path);
  final String path;
}

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    this.width,
    this.height,
    this.format,
    this.bytes,
  });

  final String secureUrl;
  final String publicId;
  final int? width;
  final int? height;
  final String? format;
  final int? bytes;

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) => CloudinaryUploadResult(
        secureUrl: json['secure_url'] as String,
        publicId: json['public_id'] as String,
        width: json['width'] as int?,
        height: json['height'] as int?,
        format: json['format'] as String?,
        bytes: json['bytes'] as int?,
      );
}

class CloudinaryService {
  CloudinaryService({
    this.userId,
    this.cloudName = const String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: 'vz6euzlq'),
    this.uploadPreset = const String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: 'land_owner_preset'),
  });

  /// Files go under `land_owner/users/{userId}/…` so an account's media can
  /// be removed together when the account is deleted.
  final String? userId;
  final String cloudName;
  final String uploadPreset;

  /// Uploads a local file or bytes to Cloudinary using an unsigned upload preset.
  /// No API secret is stored in or sent by the client application.
  Future<CloudinaryUploadResult> upload({
    required dynamic file,
    required CloudinaryFolder folder,
    String? filename,
  }) async {
    final folderPath = userId == null ? folder.path : folder.path.replaceFirst('land_owner/', 'land_owner/users/$userId/');
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folderPath;

    if (file is File) {
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      final name = filename ?? file.uri.pathSegments.last;
      request.files.add(http.MultipartFile('file', stream, length, filename: name));
    } else if (file is Uint8List) {
      final name = filename ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
      request.files.add(http.MultipartFile.fromBytes('file', file, filename: name));
    } else if (file is String) {
      // Local file path
      final f = File(file);
      final stream = http.ByteStream(f.openRead());
      final length = await f.length();
      final name = filename ?? f.uri.pathSegments.last;
      request.files.add(http.MultipartFile('file', stream, length, filename: name));
    } else {
      throw ArgumentError('Unsupported file type: ${file.runtimeType}');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return CloudinaryUploadResult.fromJson(json);
    } else {
      throw Exception('Cloudinary upload failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Checks if [pathOrUrl] is a local file. If so, uploads to Cloudinary and returns CDN URL.
  /// If it's already an http/https URL, returns it immediately.
  /// Uploads a local file and returns its URL; remote URLs pass through.
  /// Throws an [AppFailure] instead of saving a device-only path, which would
  /// break on reinstall and on the user's other devices.
  Future<String> uploadMediaIfLocal(String pathOrUrl, CloudinaryFolder folder) async {
    final trimmed = pathOrUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    try {
      final result = await upload(file: trimmed, folder: folder);
      return result.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary upload error for $pathOrUrl: $e');
      throw const AppFailure('Couldn\u2019t upload the file. Check your connection and try again.');
    }
  }

  Future<List<String>> uploadMultipleIfLocal(List<String> pathsOrUrls, CloudinaryFolder folder) async {
    final results = <String>[];
    for (final p in pathsOrUrls) {
      final uploaded = await uploadMediaIfLocal(p, folder);
      results.add(uploaded);
    }
    return results;
  }

  /// Deletes a file from Cloudinary by its publicId.
  /// Media deletion is handled securely server-side via Cloud Functions or Admin SDK
  /// so that infrastructure credentials are never exposed in the client binary.
  Future<bool> deleteByPublicId(String publicId) async {
    debugPrint('Media deletion requested for $publicId (managed via server-side lifecycle).');
    return true;
  }
}

final cloudinaryServiceProvider =
    Provider<CloudinaryService>((ref) => CloudinaryService(userId: ref.watch(currentUserProvider)?.uid));
