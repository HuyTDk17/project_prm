import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/cloudinary_config.dart';
import '../constants/app_strings.dart';
import 'media_uploader.dart';

/// Uploads files from the browser straight to Cloudinary with an unsigned
/// upload preset (no API secret inside the app).
class CloudinaryService implements MediaUploader {
  CloudinaryService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<UploadedVideo> uploadVideo({
    required Uint8List bytes,
    required String filename,
    void Function(double progress)? onProgress,
  }) async {
    final data = await _upload('video', bytes, filename, onProgress);
    final url = data['secure_url'] as String;
    return UploadedVideo(
      url: url,
      thumbnailUrl: _frameUrl(url),
      durationSec: (data['duration'] as num?)?.round() ?? 0,
    );
  }

  @override
  Future<String> uploadImage({required Uint8List bytes, required String filename}) async {
    final data = await _upload('image', bytes, filename, null);
    return data['secure_url'] as String;
  }

  Future<Map<String, dynamic>> _upload(
    String resourceType,
    Uint8List bytes,
    String filename,
    void Function(double progress)? onProgress,
  ) async {
    if (!CloudinaryConfig.isConfigured) {
      throw const UploadException(AppStrings.cloudinaryMissing);
    }
    final form = FormData.fromMap({
      'upload_preset': CloudinaryConfig.uploadPreset,
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/$resourceType/upload',
        data: form,
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
      final body = response.data;
      if (body == null || body['secure_url'] == null) {
        throw const UploadException(AppStrings.genericError);
      }
      return body;
    } on DioException catch (e) {
      final data = e.response?.data;
      String? detail;
      if (data is Map && data['error'] is Map) {
        final message = (data['error'] as Map)['message'];
        if (message is String) detail = message;
      }
      throw UploadException(detail == null ? AppStrings.genericError : 'Cloudinary: $detail');
    }
  }

  /// Cloudinary can return a frame of a video as an image: change the file
  /// extension to .jpg and ask for the frame at 1 second, 640 px wide.
  String _frameUrl(String videoUrl) {
    const marker = '/upload/';
    final start = videoUrl.indexOf(marker);
    final dot = videoUrl.lastIndexOf('.');
    if (start < 0 || dot < start) return '';
    final head = videoUrl.substring(0, start + marker.length);
    final path = videoUrl.substring(start + marker.length, dot);
    return '${head}so_1,w_640,c_limit/$path.jpg';
  }
}
