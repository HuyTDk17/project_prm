import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/media_uploader.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/channel.dart';
import '../../../shared/models/video_draft.dart';
import '../../home/data/video_repository.dart';

/// State of the upload form: chosen files, progress and errors.
/// The files go to the [MediaUploader] (Cloudinary); the video record with
/// their addresses goes to the [VideoRepository] (Firestore).
class UploadViewModel extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  UploadViewModel({required MediaUploader uploader, required VideoRepository videos})
      : _uploader = uploader,
        _videos = videos {
    _loadCategories();
  }

  /// BR06: maximum size of a video file.
  static const maxVideoBytes = 100 * 1024 * 1024;

  final MediaUploader _uploader;
  final VideoRepository _videos;

  List<String> _categories = const [];
  XFile? _video;
  int _videoSize = 0;
  String? _thumbName;
  Uint8List? _thumbBytes;
  double _progress = 0;
  bool _busy = false;
  String? _error;
  bool _disposed = false;

  List<String> get categories => _categories;
  bool get hasVideo => _video != null;
  String get videoName => _video?.name ?? '';
  int get videoSize => _videoSize;
  Uint8List? get thumbnailBytes => _thumbBytes;
  double get progress => _progress;
  bool get isBusy => _busy;
  String? get error => _error;

  Future<void> _loadCategories() async {
    try {
      _categories = await _videos.getCategories();
      notifyListeners();
    } catch (_) {
      // The form shows an empty category list; the user can retry later.
    }
  }

  Future<void> pickVideo() async {
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'Videos', extensions: ['mp4', 'mov', 'webm', 'mkv']),
    ]);
    if (file == null) return;
    final size = await file.length();
    if (size > maxVideoBytes) {
      _error = AppStrings.videoTooLarge;
      notifyListeners();
      return;
    }
    _video = file;
    _videoSize = size;
    _error = null;
    notifyListeners();
  }

  Future<void> pickThumbnail() async {
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'Images', extensions: ['jpg', 'jpeg', 'png', 'webp']),
    ]);
    if (file == null) return;
    _thumbName = file.name;
    _thumbBytes = await file.readAsBytes();
    notifyListeners();
  }

  void removeThumbnail() {
    _thumbName = null;
    _thumbBytes = null;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Uploads the files and saves the video. Returns true on success.
  Future<bool> submit({
    required String title,
    required String description,
    required String? category,
    required bool isPublic,
    required AppUser user,
    required Channel channel,
  }) async {
    final file = _video;
    if (file == null) return _fail(AppStrings.videoRequired);
    if (_videoSize > maxVideoBytes) return _fail(AppStrings.videoTooLarge);
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 100) return _fail(AppStrings.titleInvalid);
    if (category == null) return _fail(AppStrings.categoryRequired);

    _busy = true;
    _progress = 0;
    _error = null;
    notifyListeners();
    try {
      final bytes = await file.readAsBytes();
      final uploaded = await _uploader.uploadVideo(
        bytes: bytes,
        filename: file.name,
        onProgress: (p) {
          _progress = p * 0.95;
          notifyListeners();
        },
      );
      var thumbnailUrl = uploaded.thumbnailUrl;
      final thumb = _thumbBytes;
      if (thumb != null) {
        thumbnailUrl = await _uploader.uploadImage(bytes: thumb, filename: _thumbName ?? 'thumbnail.jpg');
      }
      await _videos.createVideo(VideoDraft(
        ownerId: user.id,
        channelId: channel.id,
        channelName: channel.name,
        title: cleanTitle,
        description: description.trim(),
        categoryName: category,
        videoUrl: uploaded.url,
        thumbnailUrl: thumbnailUrl,
        durationSec: uploaded.durationSec,
        isPublic: isPublic,
      ));
      _progress = 1;
      return true;
    } on UploadException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = AppStrings.genericError;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  bool _fail(String message) {
    _error = message;
    notifyListeners();
    return false;
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
