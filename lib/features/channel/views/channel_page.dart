import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/channel_avatar.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/video_card.dart';
import '../../../shared/widgets/video_sliver_grid.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/auth_prompt.dart';
import '../../video_player/data/engagement_repository.dart';
import '../data/channel_repository.dart';
import '../viewmodels/channel_viewmodel.dart';

/// Public page of a channel: banner, avatar, numbers, description, public videos.
/// Guests can look at it; subscribing asks them to log in (BR05).
class ChannelPage extends StatelessWidget {
  const ChannelPage({super.key, required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(channelId),
      create: (ctx) => ChannelViewModel(
        channelId: channelId,
        channels: ctx.read<ChannelRepository>(),
        engagement: ctx.read<EngagementRepository>(),
        user: ctx.read<AuthViewModel>().user,
      ),
      child: const _ChannelView(),
    );
  }
}

class _ChannelView extends StatelessWidget {
  const _ChannelView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChannelViewModel>();
    final info = vm.info;

    Widget body;
    if (vm.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (info == null || vm.error != null) {
      body = StateView(
        icon: Icons.live_tv_rounded,
        title: 'Channel not found',
        message: 'This channel may have been removed.',
        actionLabel: 'Back to Home',
        onAction: () => context.go(RouteNames.home),
      );
    } else {
      body = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(vm: vm)),
          if (vm.videos.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: StateView(
                icon: Icons.video_library_outlined,
                title: 'No videos yet',
                message: 'This channel has not published a public video.',
              ),
            )
          else
            VideoSliverGrid(
              itemCount: vm.videos.length,
              itemBuilder: (context, index) {
                final v = vm.videos[index];
                return VideoCard(
                  video: v,
                  onTap: () => context.push(RouteNames.video(v.id), extra: v),
                );
              },
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
        title: Text(info?.name ?? ''),
      ),
      body: SafeArea(child: body),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.vm});

  final ChannelViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final info = vm.info!;
    final colors = AppColors.thumbGradients[info.id.hashCode.abs() % AppColors.thumbGradients.length];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                image: (info.bannerUrl == null || info.bannerUrl!.isEmpty)
                    ? null
                    : DecorationImage(image: NetworkImage(info.bannerUrl!), fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Wrap(
                spacing: 20,
                runSpacing: 14,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ChannelAvatar(name: info.name, size: 88, imageUrl: info.avatarUrl),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info.name, style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${Formatters.compactCount(vm.subscriberCount)} subscribers, '
                          '${vm.videos.length == 1 ? '1 video' : '${vm.videos.length} videos'}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (info.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(info.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                  if (vm.isOwn)
                    Chip(avatar: const Icon(Icons.verified_user_outlined, size: 18), label: const Text('Your channel'))
                  else if (vm.subscribed)
                    OutlinedButton(
                      onPressed: () {
                        if (requireLogin(context, 'Log in to subscribe to this channel.')) vm.toggleSubscribe();
                      },
                      child: const Text('Subscribed'),
                    )
                  else
                    FilledButton(
                      onPressed: () {
                        if (requireLogin(context, 'Log in to subscribe to this channel.')) vm.toggleSubscribe();
                      },
                      child: const Text('Subscribe'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Text('Videos', style: theme.textTheme.titleLarge),
            ),
          ],
        ),
      ),
    );
  }
}
