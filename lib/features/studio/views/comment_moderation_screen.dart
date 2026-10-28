import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/context_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/channel_avatar.dart';
import '../../../shared/widgets/choice_field.dart';
import '../../../shared/widgets/state_views.dart';
import '../../video_player/data/engagement_repository.dart';
import '../data/studio_repository.dart';
import '../viewmodels/studio_viewmodel.dart';

/// Comments on the videos of the active channel; the owner can delete them (UC21, BR11).
class CommentModerationScreen extends StatefulWidget {
  const CommentModerationScreen({super.key});

  @override
  State<CommentModerationScreen> createState() => _CommentModerationScreenState();
}

class _CommentModerationScreenState extends State<CommentModerationScreen> {
  List<ModerationComment> _items = const [];
  bool _loading = true;
  String? _error;
  String _videoFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final studio = context.read<StudioViewModel>();
      if (studio.videos.isEmpty) await studio.refresh();
      if (!mounted) return;
      final items = await context.read<StudioRepository>().getComments(studio.videos);
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _error = AppStrings.genericError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(ModerationComment item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this comment?'),
        content: Text('"${item.comment.content}"', maxLines: 4, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await context.read<EngagementRepository>().deleteComment(videoId: item.videoId, commentId: item.comment.id);
      if (!mounted) return;
      setState(() => _items = _items.where((c) => c.comment.id != item.comment.id).toList());
      context.read<StudioViewModel>().refresh();
    } catch (_) {
      if (mounted) context.showSnack(AppStrings.genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioViewModel>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shown = _videoFilter == 'all' ? _items : _items.where((c) => c.videoId == _videoFilter).toList();
    final filterLabel = _videoFilter == 'all'
        ? 'All videos'
        : studio.videoById(_videoFilter)?.title ?? 'All videos';

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = StateView(
        icon: Icons.wifi_off_rounded,
        title: AppStrings.genericError,
        message: 'We could not load the comments.',
        actionLabel: 'Try again',
        onAction: _load,
      );
    } else {
      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ChoiceField(
              label: 'Filter by video',
              value: filterLabel,
              hint: 'All videos',
              icon: Icons.video_library_outlined,
              onTap: () async {
                final picked = await pickOne(
                  context,
                  title: 'Video',
                  options: [('all', 'All videos'), for (final v in studio.videos) (v.id, v.title)],
                  selected: _videoFilter,
                );
                if (picked != null) setState(() => _videoFilter = picked);
              },
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? const StateView(
                    icon: Icons.forum_outlined,
                    title: AppStrings.noVideos,
                    message: 'No comments on these videos yet.',
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 32),
                      itemCount: shown.length,
                      separatorBuilder: (context, index) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final item = shown[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ChannelAvatar(name: item.comment.authorName, size: 38),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.comment.authorName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelLarge,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        Formatters.timeAgo(item.comment.createdAt),
                                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(item.comment.content),
                                  const SizedBox(height: 4),
                                  Text(
                                    'on: ${item.videoTitle}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete comment',
                              onPressed: () => _delete(item),
                              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
        ),
        title: const Text('Comments'),
      ),
      body: SafeArea(
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: body)),
      ),
    );
  }
}
