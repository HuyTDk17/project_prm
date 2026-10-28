import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/video.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/video_card.dart';
import '../../../shared/widgets/video_sliver_grid.dart';
import '../../studio/views/upload_entry.dart';
import '../viewmodels/home_viewmodel.dart';
import 'widgets/user_menu_button.dart';

/// The home feed: app bar with search and categories, then a responsive
/// list (1 column) or grid (2-5 columns) of videos.
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: CustomScrollView(
        // Lets pull-to-refresh work even when the list is short.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const _FeedAppBar(),
          ..._buildContent(context, vm),
        ],
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, HomeViewModel vm) {
    switch (vm.status) {
      case LoadStatus.loading:
        return [
          VideoSliverGrid(
            itemCount: 8,
            itemBuilder: (context, index) => const VideoCardSkeleton(),
          ),
        ];
      case LoadStatus.error:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: StateView(
              icon: Icons.wifi_off_rounded,
              title: AppStrings.genericError,
              message: 'We could not load the videos. Check your connection and try again.',
              actionLabel: 'Try again',
              onAction: vm.load,
            ),
          ),
        ];
      case LoadStatus.empty:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: StateView(
              icon: Icons.video_library_outlined,
              title: AppStrings.noVideos,
              message: 'There is nothing in "${vm.selectedCategory}" yet. Try another category.',
              actionLabel: 'Show all videos',
              onAction: () => vm.selectCategory(HomeViewModel.allCategories),
            ),
          ),
        ];
      case LoadStatus.success:
        final videos = vm.videos;
        return [
          VideoSliverGrid(
            itemCount: videos.length,
            itemBuilder: (context, index) => _FeedItem(video: videos[index]),
          ),
        ];
    }
  }
}

class _FeedItem extends StatelessWidget {
  const _FeedItem({required this.video});

  final Video video;

  @override
  Widget build(BuildContext context) {
    return VideoCard(
      video: video,
      onTap: () => context.push(RouteNames.video(video.id), extra: video),
      onChannelTap: video.channelId == null ? null : () => context.push(RouteNames.channel(video.channelId!)),
    );
  }
}

class _FeedAppBar extends StatelessWidget {
  const _FeedAppBar();

  @override
  Widget build(BuildContext context) {
    final wide = context.screenWidth >= 720;
    final vm = context.read<HomeViewModel>();

    return SliverAppBar(
      floating: true,
      snap: true,
      toolbarHeight: 68,
      titleSpacing: 16,
      title: wide
          ? Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: const _SearchField(),
              ),
            )
          : const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: BrandLogo(size: 32),
            ),
      actions: [
        if (wide)
          IconButton(
            tooltip: 'Refresh',
            onPressed: vm.refresh,
            icon: const Icon(Icons.refresh_rounded),
          )
        else
          IconButton(
            tooltip: 'Search',
            onPressed: () => context.push(RouteNames.search),
            icon: const Icon(Icons.search_rounded),
          ),
        IconButton(
          tooltip: 'Create',
          onPressed: () => startUpload(context),
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
        const UserMenuButton(),
        const SizedBox(width: 8),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: _CategoryBar(),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(RouteNames.search),
        child: SizedBox(
          height: 46,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search videos and channels',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
                // Keyboard shortcut hint (press / on the keyboard).
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('/', style: Theme.of(context).textTheme.labelMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final categories = vm.categories;

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final name = categories[index];
          return _CategoryChip(
            label: name,
            selected: name == vm.selectedCategory,
            onTap: () => vm.selectCategory(name),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? scheme.onSurface : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? scheme.surface : scheme.onSurface,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
