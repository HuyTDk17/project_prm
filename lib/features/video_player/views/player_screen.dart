import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/comment.dart';
import '../../../shared/models/video.dart';
import '../../../shared/widgets/channel_avatar.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/video_thumbnail.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/auth_prompt.dart';
import '../../home/data/video_repository.dart';
import '../data/engagement_repository.dart';
import '../viewmodels/player_viewmodel.dart';
import 'widgets/video_surface.dart';

/// Watch a video: player, like, subscribe, comments and related videos.
/// Guests can watch and read; like, comment and subscribe ask them to log in (BR05).
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, required this.videoId, this.initial});

  final String videoId;
  final Video? initial;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(videoId),
      create: (ctx) => PlayerViewModel(
        videoId: videoId,
        initial: initial,
        engagement: ctx.read<EngagementRepository>(),
        videos: ctx.read<VideoRepository>(),
        user: ctx.read<AuthViewModel>().user,
      ),
      child: const _PlayerView(),
    );
  }
}

class _PlayerView extends StatelessWidget {
  const _PlayerView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();
    final video = vm.video;

    Widget body;
    if (vm.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (video == null || vm.error != null) {
      body = StateView(
        icon: Icons.videocam_off_outlined,
        title: 'Video not available',
        message: 'It may have been deleted or made private.',
        actionLabel: 'Back to Home',
        onAction: () => context.go(RouteNames.home),
      );
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;
          final main = _MainColumn(vm: vm, video: video);
          if (!wide) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VideoSurface(key: ValueKey(video.id), url: video.videoUrl),
                  Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: main),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _RelatedList(videos: vm.related),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 12, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: VideoSurface(key: ValueKey(video.id), url: video.videoUrl),
                          ),
                          const SizedBox(height: 16),
                          main,
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 24, 32),
                      child: _RelatedList(videos: vm.related),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
        ),
      ),
      body: SafeArea(child: body),
    );
  }
}

/// Title, numbers, actions, channel row, description and comments.
class _MainColumn extends StatelessWidget {
  const _MainColumn({required this.vm, required this.video});

  final PlayerViewModel vm;
  final Video video;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(video.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          '${Formatters.compactCount(video.viewCount)} views, ${Formatters.timeAgo(video.createdAt)}',
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: video.channelId == null ? null : () => context.push(RouteNames.channel(video.channelId!)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChannelAvatar(name: video.channelName, size: 44),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(video.channelName, style: theme.textTheme.titleMedium),
                      Text(
                        '${Formatters.compactCount(vm.subscriberCount)} subscribers',
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!vm.isOwnChannel)
              vm.subscribed
                  ? OutlinedButton(
                      onPressed: () {
                        if (requireLogin(context, 'Log in to subscribe to this channel.')) vm.toggleSubscribe();
                      },
                      child: const Text('Subscribed'),
                    )
                  : FilledButton(
                      onPressed: () {
                        if (requireLogin(context, 'Log in to subscribe to this channel.')) vm.toggleSubscribe();
                      },
                      child: const Text('Subscribe'),
                    ),
            FilledButton.tonalIcon(
              onPressed: () {
                if (requireLogin(context, 'Log in to like this video.')) vm.toggleLike();
              },
              icon: Icon(vm.liked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined),
              label: Text(Formatters.compactCount(vm.likeCount)),
            ),
          ],
        ),
        if (video.description.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _Description(text: video.description),
        ],
        const SizedBox(height: 24),
        _CommentsSection(vm: vm),
      ],
    );
  }
}

class _Description extends StatefulWidget {
  const _Description({required this.text});

  final String text;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            widget.text,
            maxLines: _open ? null : 3,
            overflow: _open ? TextOverflow.visible : TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _CommentsSection extends StatefulWidget {
  const _CommentsSection({required this.vm});

  final PlayerViewModel vm;

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!requireLogin(context, 'Log in to comment on this video.')) return;
    final ok = await widget.vm.addComment(_controller.text);
    if (ok) _controller.clear();
  }

  Future<void> _delete(Comment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this comment?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) widget.vm.deleteComment(comment);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final vm = widget.vm;
    final user = context.select<AuthViewModel, AppUser?>((a) => a.user);
    final video = vm.video;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comments (${video?.commentCount ?? vm.comments.length})', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChannelAvatar(name: user?.displayName ?? '?', size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                readOnly: user == null,
                onTap: user == null ? () => requireLogin(context, 'Log in to comment on this video.') : null,
                onChanged: (_) => vm.clearCommentError(),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: user == null ? 'Log in to comment' : 'Add a comment',
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  errorText: vm.commentError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: vm.isSendingComment
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          tooltip: 'Send',
                          onPressed: _send,
                          icon: Icon(Icons.send_rounded, color: scheme.primary),
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (vm.comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No comments yet. Be the first.',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        for (final comment in vm.comments)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChannelAvatar(name: comment.authorName, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              comment.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Formatters.timeAgo(comment.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(comment.content, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                if (vm.canDelete(comment))
                  IconButton(
                    tooltip: 'Delete comment',
                    onPressed: () => _delete(comment),
                    icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RelatedList extends StatelessWidget {
  const _RelatedList({required this.videos});

  final List<Video> videos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (videos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Up next', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final v in videos)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.pushReplacement(RouteNames.video(v.id), extra: v),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 168,
                    child: ClipRRect(borderRadius: BorderRadius.circular(12), child: VideoThumbnail(video: v)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          v.channelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          '${Formatters.compactCount(v.viewCount)} views',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
