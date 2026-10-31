import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/media_uploader.dart';
import '../../../core/utils/context_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/channel.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/choice_field.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/widgets/auth_error_banner.dart';
import '../../home/data/video_repository.dart';
import '../../home/viewmodels/home_viewmodel.dart';
import '../viewmodels/studio_viewmodel.dart';
import '../viewmodels/upload_viewmodel.dart';

/// Upload a video: pick the file (and optional thumbnail), describe it and
/// choose the category, visibility and the channel to publish to.
class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => UploadViewModel(
        uploader: ctx.read<MediaUploader>(),
        videos: ctx.read<VideoRepository>(),
      ),
      child: const _UploadView(),
    );
  }
}

class _UploadView extends StatefulWidget {
  const _UploadView();

  @override
  State<_UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<_UploadView> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String? _category;
  String? _categoryError;
  bool _isPublic = true;
  String? _channelId;

  @override
  void initState() {
    super.initState();
    // BR19: the form starts with the active channel.
    _channelId = context.read<AuthViewModel>().activeChannel?.id;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState?.validate() ?? false;
    if (_category == null) setState(() => _categoryError = AppStrings.categoryRequired);
    if (!formOk || _category == null) return;

    final auth = context.read<AuthViewModel>();
    final user = auth.user;
    final channel = auth.channels.where((c) => c.id == _channelId).firstOrNull ?? auth.activeChannel;
    if (user == null || channel == null) return;

    final ok = await context.read<UploadViewModel>().submit(
          title: _title.text,
          description: _description.text,
          category: _category,
          isPublic: _isPublic,
          user: user,
          channel: channel,
        );
    if (!mounted || !ok) return;
    context.read<HomeViewModel>().refresh();
    context.read<StudioViewModel>().refresh();
    context.showSnack(AppStrings.uploadSuccess);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UploadViewModel>();
    final channels = context.select<AuthViewModel, List<Channel>>((a) => a.channels);
    final theme = Theme.of(context);

    final media = _MediaColumn(vm: vm);
    final form = _FormColumn(
      formKey: _formKey,
      title: _title,
      description: _description,
      categories: vm.categories,
      category: _category,
      categoryError: _categoryError,
      onCategory: (value) => setState(() {
        _category = value;
        _categoryError = null;
      }),
      isPublic: _isPublic,
      onVisibility: (value) => setState(() => _isPublic = value),
      channels: channels,
      channelId: _channelId,
      onChannel: (value) => setState(() => _channelId = value),
      busy: vm.isBusy,
    );

    return PopScope(
      canPop: !vm.isBusy,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close',
            onPressed: vm.isBusy ? null : () => context.pop(),
            icon: const Icon(Icons.close_rounded),
          ),
          title: const Text('Upload video'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    final body = wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: media),
                              const SizedBox(width: 32),
                              Expanded(flex: 6, child: form),
                            ],
                          )
                        : Column(children: [media, const SizedBox(height: 24), form]);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        body,
                        AuthErrorBanner(message: vm.error),
                        if (vm.isBusy) ...[
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(value: vm.progress, minHeight: 8),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Uploading... ${(vm.progress * 100).round()}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: wide ? 280 : double.infinity),
                            child: AppButton(
                              label: 'Upload',
                              icon: Icons.upload_rounded,
                              isLoading: vm.isBusy,
                              onPressed: _submit,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Left side: video file and thumbnail.
class _MediaColumn extends StatelessWidget {
  const _MediaColumn({required this.vm});

  final UploadViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final picked = vm.hasVideo;
    final sizeMb = (vm.videoSize / (1024 * 1024)).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: vm.isBusy ? null : vm.pickVideo,
            child: Container(
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: picked ? scheme.primary : scheme.outlineVariant,
                  width: picked ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    picked ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                    size: 44,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    picked ? vm.videoName : 'Select a video file',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    picked ? '$sizeMb MB. Tap to change.' : 'MP4, MOV or WebM, up to 40 MB',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 128,
                height: 72,
                color: scheme.surfaceContainerHighest,
                child: vm.thumbnailBytes == null
                    ? Icon(Icons.image_outlined, color: scheme.onSurfaceVariant)
                    : Image.memory(vm.thumbnailBytes!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thumbnail (optional)', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    'Image up to 5 MB (resized automatically). Without one, a frame of the video is used.',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Wrap(
                    children: [
                      TextButton(
                        onPressed: vm.isBusy ? null : vm.pickThumbnail,
                        child: const Text('Choose image'),
                      ),
                      if (vm.thumbnailBytes != null)
                        TextButton(
                          onPressed: vm.isBusy ? null : vm.removeThumbnail,
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Right side: title, description, category, visibility and channel.
class _FormColumn extends StatelessWidget {
  const _FormColumn({
    required this.formKey,
    required this.title,
    required this.description,
    required this.categories,
    required this.category,
    required this.categoryError,
    required this.onCategory,
    required this.isPublic,
    required this.onVisibility,
    required this.channels,
    required this.channelId,
    required this.onChannel,
    required this.busy,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController title;
  final TextEditingController description;
  final List<String> categories;
  final String? category;
  final String? categoryError;
  final ValueChanged<String> onCategory;
  final bool isPublic;
  final ValueChanged<bool> onVisibility;
  final List<Channel> channels;
  final String? channelId;
  final ValueChanged<String> onChannel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final channel = channels.where((c) => c.id == channelId).firstOrNull;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: title,
            label: 'Title *',
            hint: 'Give your video a title',
            icon: Icons.title_rounded,
            textInputAction: TextInputAction.next,
            validator: Validators.videoTitle,
          ),
          const SizedBox(height: 18),
          AppTextField(
            controller: description,
            label: 'Description',
            hint: 'Tell viewers about your video',
            maxLines: 5,
            minLines: 3,
          ),
          const SizedBox(height: 18),
          ChoiceField(
            label: 'Category *',
            value: category,
            hint: 'Choose a category',
            icon: Icons.category_outlined,
            errorText: categoryError,
            onTap: busy || categories.isEmpty
                ? null
                : () async {
                    final picked = await pickOne(
                      context,
                      title: 'Category',
                      options: [for (final c in categories) (c, c)],
                      selected: category,
                    );
                    if (picked != null) onCategory(picked);
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
            selected: {isPublic},
            onSelectionChanged: busy ? null : (s) => onVisibility(s.first),
          ),
          const SizedBox(height: 6),
          Text(
            isPublic
                ? 'Everybody can watch this video, guests included.'
                : 'Only you can see this video.',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          ChoiceField(
            label: 'Publish to channel',
            value: channel?.name,
            hint: 'Choose a channel',
            icon: Icons.live_tv_rounded,
            onTap: busy || channels.length < 2
                ? null
                : () async {
                    final picked = await pickOne(
                      context,
                      title: 'Publish to channel',
                      options: [for (final c in channels) (c.id, c.name)],
                      selected: channelId,
                    );
                    if (picked != null) onChannel(picked);
                  },
          ),
        ],
      ),
    );
  }
}
