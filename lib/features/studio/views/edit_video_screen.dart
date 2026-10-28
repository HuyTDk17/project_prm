import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/media_uploader.dart';
import '../../../core/utils/context_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/video.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/choice_field.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/video_thumbnail.dart';
import '../../auth/views/widgets/auth_error_banner.dart';
import '../../home/data/video_repository.dart';
import '../viewmodels/studio_viewmodel.dart';

/// Edit the details of a video, or delete it (UC19, UC20).
class EditVideoScreen extends StatefulWidget {
  const EditVideoScreen({super.key, required this.videoId, this.initial});

  final String videoId;
  final Video? initial;

  @override
  State<EditVideoScreen> createState() => _EditVideoScreenState();
}

class _EditVideoScreenState extends State<EditVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  Video? _video;
  List<String> _categories = const [];
  String? _category;
  bool _isPublic = true;
  Uint8List? _thumbBytes;
  String _thumbName = 'thumbnail.jpg';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _video = widget.initial;
    if (_video != null) _fill(_video!);
    context.read<VideoRepository>().getCategories().then((list) {
      if (mounted) setState(() => _categories = list);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_video == null) {
      final found = context.read<StudioViewModel>().videoById(widget.videoId);
      if (found != null) {
        _video = found;
        _fill(found);
      }
    }
  }

  void _fill(Video v) {
    _title.text = v.title;
    _description.text = v.description;
    _category = v.categoryName;
    _isPublic = v.isPublic;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'Images', extensions: ['jpg', 'jpeg', 'png', 'webp']),
    ]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _thumbBytes = bytes;
      _thumbName = file.name;
    });
  }

  Future<void> _save() async {
    final video = _video;
    if (video == null) return;
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;
    if (_category == null) {
      setState(() => _error = AppStrings.categoryRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? thumbnailUrl;
    try {
      final bytes = _thumbBytes;
      if (bytes != null) {
        thumbnailUrl = await context.read<MediaUploader>().uploadImage(bytes: bytes, filename: _thumbName);
      }
    } on UploadException catch (e) {
      if (mounted) setState(() {
        _busy = false;
        _error = e.message;
      });
      return;
    } catch (_) {
      if (mounted) setState(() {
        _busy = false;
        _error = AppStrings.genericError;
      });
      return;
    }
    if (!mounted) return;
    final error = await context.read<StudioViewModel>().updateVideo(
          video,
          title: _title.text.trim(),
          description: _description.text.trim(),
          category: _category!,
          isPublic: _isPublic,
          thumbnailUrl: thumbnailUrl,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    context.showSnack(AppStrings.videoUpdated);
    context.pop();
  }

  Future<void> _delete() async {
    final video = _video;
    if (video == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteVideoConfirm),
        content: Text('"${video.title}" will be removed with its comments and likes.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    final error = await context.read<StudioViewModel>().deleteVideo(video);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    context.showSnack(AppStrings.videoDeleted);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget body;
    if (video == null) {
      body = StateView(
        icon: Icons.videocam_off_outlined,
        title: 'Video not found',
        message: 'It may have been deleted.',
        actionLabel: 'Back to Studio',
        onAction: () => context.go(RouteNames.home),
      );
    } else {
      final preview = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _thumbBytes == null
                  ? VideoThumbnail(video: video)
                  : Image.memory(_thumbBytes!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickThumbnail,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Change thumbnail'),
          ),
        ],
      );
      final form = Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _title,
              label: 'Title *',
              icon: Icons.title_rounded,
              textInputAction: TextInputAction.next,
              validator: Validators.videoTitle,
            ),
            const SizedBox(height: 18),
            AppTextField(controller: _description, label: 'Description', maxLines: 5, minLines: 3),
            const SizedBox(height: 18),
            ChoiceField(
              label: 'Category *',
              value: _category,
              hint: 'Choose a category',
              icon: Icons.category_outlined,
              onTap: _busy || _categories.isEmpty
                  ? null
                  : () async {
                      final picked = await pickOne(
                        context,
                        title: 'Category',
                        options: [for (final c in _categories) (c, c)],
                        selected: _category,
                      );
                      if (picked != null) setState(() => _category = picked);
                    },
            ),
            const SizedBox(height: 18),
            Text('Visibility', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Public'), icon: Icon(Icons.public_rounded)),
                ButtonSegment(value: false, label: Text('Private'), icon: Icon(Icons.lock_outline_rounded)),
              ],
              selected: {_isPublic},
              onSelectionChanged: _busy ? null : (s) => setState(() => _isPublic = s.first),
            ),
            const SizedBox(height: 6),
            Text(
              _isPublic ? 'Everybody can watch this video, guests included.' : 'Only you can see this video.',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
      body = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: preview),
                          const SizedBox(width: 32),
                          Expanded(flex: 6, child: form),
                        ],
                      )
                    : Column(children: [preview, const SizedBox(height: 24), form]),
                AuthErrorBanner(message: _error),
                const SizedBox(height: 24),
                AppButton(label: 'Save changes', icon: Icons.check_rounded, isLoading: _busy, onPressed: _save),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _delete,
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  label: Text('Delete video', style: TextStyle(color: scheme.error)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: scheme.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _busy ? null : () => context.canPop() ? context.pop() : context.go(RouteNames.home),
        ),
        title: const Text('Edit video'),
      ),
      body: SafeArea(
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: body)),
      ),
    );
  }
}
