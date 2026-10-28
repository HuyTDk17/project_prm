import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/context_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/video.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/video_thumbnail.dart';
import '../../../shared/widgets/visibility_badge.dart';
import '../../search/data/search_service.dart';
import '../viewmodels/studio_viewmodel.dart';
import 'upload_entry.dart';

enum _Filter { all, public, private }

/// All videos of the active channel (UC18): search, filter by visibility,
/// edit and delete (UC19, UC20).
class ManageVideosScreen extends StatefulWidget {
  const ManageVideosScreen({super.key});

  @override
  State<ManageVideosScreen> createState() => _ManageVideosScreenState();
}

class _ManageVideosScreenState extends State<ManageVideosScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;

  Future<void> _delete(Video video) async {
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
    final error = await context.read<StudioViewModel>().deleteVideo(video);
    if (!mounted) return;
    context.showSnack(error ?? AppStrings.videoDeleted);
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioViewModel>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final q = SearchService.normalize(_query);
    final videos = studio.videos.where((v) {
      if (_filter == _Filter.public && !v.isPublic) return false;
      if (_filter == _Filter.private && v.isPublic) return false;
      return q.isEmpty || SearchService.normalize(v.title).contains(q);
    }).toList();

    Widget body;
    if (studio.isLoading && studio.videos.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (studio.videos.isEmpty) {
      body = StateView(
        icon: Icons.video_call_outlined,
        title: AppStrings.noVideos,
        message: 'Upload your first video to manage it here.',
        actionLabel: 'Upload video',
        onAction: () => startUpload(context),
      );
    } else {
      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search my videos',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: scheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final f in _Filter.values) ...[
                  ChoiceChip(
                    label: Text(f == _Filter.all ? 'All' : f == _Filter.public ? 'Public' : 'Private'),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: videos.isEmpty
                ? const StateView(
                    icon: Icons.search_off_rounded,
                    title: AppStrings.noVideos,
                    message: 'No video matches your search or filter.',
                  )
                : RefreshIndicator(
                    onRefresh: studio.refresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 96),
                      itemCount: videos.length,
                      itemBuilder: (context, index) => _VideoRow(
                        video: videos[index],
                        onDelete: () => _delete(videos[index]),
                      ),
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
        title: const Text('Manage videos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => startUpload(context),
        icon: const Icon(Icons.upload_rounded),
        label: const Text('Upload'),
      ),
      body: SafeArea(
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: body)),
      ),
    );
  }
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({required this.video, required this.onDelete});

  final Video video;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push(RouteNames.studioEdit(video.id), extra: video),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: VideoThumbnail(video: video)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  VisibilityBadge(isPublic: video.isPublic),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.compactCount(video.viewCount)} views, '
                    '${Formatters.compactCount(video.likeCount)} likes, '
                    '${Formatters.compactCount(video.commentCount)} comments',
                    style: small,
                  ),
                  Text(Formatters.timeAgo(video.createdAt), style: small),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (value) {
                if (value == 'edit') context.push(RouteNames.studioEdit(video.id), extra: video);
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
