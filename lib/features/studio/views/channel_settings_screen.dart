import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/media_uploader.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/context_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/channel.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/channel_avatar.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/widgets/auth_error_banner.dart';
import '../../channel/data/channel_repository.dart';
import '../data/studio_repository.dart';
import '../viewmodels/studio_viewmodel.dart';

/// Edit name, description, avatar and banner of the active channel (UC22, BR04).
class ChannelSettingsScreen extends StatefulWidget {
  const ChannelSettingsScreen({super.key});

  @override
  State<ChannelSettingsScreen> createState() => _ChannelSettingsScreenState();
}

class _ChannelSettingsScreenState extends State<ChannelSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  Channel? _channel;
  ChannelInfo? _info;
  Uint8List? _avatarBytes;
  String _avatarName = 'avatar.jpg';
  Uint8List? _bannerBytes;
  String _bannerName = 'banner.jpg';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final channel = context.read<AuthViewModel>().activeChannel;
    _channel = channel;
    if (channel != null) {
      _name.text = channel.name;
      _load(channel);
    }
  }

  Future<void> _load(Channel channel) async {
    try {
      final info = await context.read<ChannelRepository>().getChannel(channel.id);
      if (!mounted || info == null) return;
      setState(() {
        _info = info;
        _description.text = info.description;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<(Uint8List, String)?> _pickImage() async {
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'Images', extensions: ['jpg', 'jpeg', 'png', 'webp']),
    ]);
    if (file == null) return null;
    return (await file.readAsBytes(), file.name);
  }

  Future<void> _save() async {
    final channel = _channel;
    final user = context.read<AuthViewModel>().user;
    if (channel == null || user == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uploader = context.read<MediaUploader>();
      String? avatarUrl;
      String? bannerUrl;
      if (_avatarBytes != null) avatarUrl = await uploader.uploadImage(bytes: _avatarBytes!, filename: _avatarName);
      if (_bannerBytes != null) bannerUrl = await uploader.uploadImage(bytes: _bannerBytes!, filename: _bannerName);
      if (!mounted) return;
      final name = _name.text.trim();
      final description = _description.text.trim();
      await context.read<StudioRepository>().updateChannel(
            channelId: channel.id,
            ownerId: user.id,
            oldName: channel.name,
            name: name,
            description: description,
            avatarUrl: avatarUrl,
            bannerUrl: bannerUrl,
          );
      if (!mounted) return;
      context.read<AuthViewModel>().updateChannel(Channel(
            id: channel.id,
            ownerId: channel.ownerId,
            name: name,
            description: description,
            isDefault: channel.isDefault,
          ));
      context.read<StudioViewModel>().refresh();
      context.showSnack(AppStrings.channelSaved);
      context.pop();
    } on ChannelException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on UploadException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = AppStrings.genericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final channel = _channel;
    final studio = context.watch<StudioViewModel>();
    final colors = AppColors.thumbGradients[(channel?.id ?? '').hashCode.abs() % AppColors.thumbGradients.length];

    Widget banner = Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        image: _bannerBytes != null
            ? DecorationImage(image: MemoryImage(_bannerBytes!), fit: BoxFit.cover)
            : (_info?.bannerUrl != null && _info!.bannerUrl!.isNotEmpty)
                ? DecorationImage(image: NetworkImage(_info!.bannerUrl!), fit: BoxFit.cover)
                : null,
      ),
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.all(10),
      child: FilledButton.tonalIcon(
        onPressed: _busy
            ? null
            : () async {
                final picked = await _pickImage();
                if (picked != null && mounted) setState(() {
                  _bannerBytes = picked.$1;
                  _bannerName = picked.$2;
                });
              },
        icon: const Icon(Icons.image_outlined),
        label: const Text('Change banner'),
      ),
    );

    final avatar = Row(
      children: [
        _avatarBytes != null
            ? ClipOval(child: Image.memory(_avatarBytes!, width: 72, height: 72, fit: BoxFit.cover))
            : ChannelAvatar(name: _name.text.isEmpty ? (channel?.name ?? '?') : _name.text, size: 72, imageUrl: _info?.avatarUrl),
        const SizedBox(width: 14),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  final picked = await _pickImage();
                  if (picked != null && mounted) setState(() {
                    _avatarBytes = picked.$1;
                    _avatarName = picked.$2;
                  });
                },
          icon: const Icon(Icons.account_circle_outlined),
          label: const Text('Change avatar'),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _busy ? null : () => context.canPop() ? context.pop() : context.go(RouteNames.home),
        ),
        title: const Text('Channel settings'),
      ),
      body: SafeArea(
        child: channel == null
            ? const Center(child: Text('No active channel.'))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          banner,
                          const SizedBox(height: 16),
                          avatar,
                          const SizedBox(height: 24),
                          AppTextField(
                            controller: _name,
                            label: 'Channel name *',
                            icon: Icons.live_tv_rounded,
                            textInputAction: TextInputAction.next,
                            validator: Validators.channelName,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 18),
                          AppTextField(
                            controller: _description,
                            label: 'Description',
                            hint: 'Tell people what your channel is about',
                            maxLines: 5,
                            minLines: 3,
                            validator: (v) => (v ?? '').length > 1000 ? AppStrings.descriptionTooLong : null,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '${Formatters.compactCount(studio.subscribers)} subscribers, '
                            '${studio.videoCount == 1 ? '1 video' : '${studio.videoCount} videos'}',
                            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          AuthErrorBanner(message: _error),
                          const SizedBox(height: 24),
                          AppButton(label: 'Save', icon: Icons.check_rounded, isLoading: _busy, onPressed: _save),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
