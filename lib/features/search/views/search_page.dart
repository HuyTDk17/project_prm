import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/video.dart';
import '../../../shared/widgets/channel_avatar.dart';
import '../../../shared/widgets/shimmer.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/video_thumbnail.dart';
import '../data/recent_searches.dart';
import '../data/search_index.dart';
import '../data/search_service.dart';
import '../viewmodels/search_viewmodel.dart';

/// Search videos and channels.
///  - results update while typing (short pause), no accents needed,
///  - matches are shown in bold, results are ranked,
///  - filter by category, sort by relevance / newest / most viewed,
///  - recent searches, Enter to confirm, Esc to clear or go back.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => SearchViewModel(
        index: ctx.read<SearchIndex>(),
        recent: RecentSearches(),
        initialQuery: initialQuery,
      ),
      child: _SearchView(initialQuery: initialQuery),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView({required this.initialQuery});

  final String initialQuery;

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialQuery);
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setText(String text) {
    _controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  void _clear(SearchViewModel vm) {
    _controller.clear();
    vm.onQueryChanged('');
    _focus.requestFocus();
  }

  void _back() => context.canPop() ? context.pop() : context.go(RouteNames.home);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();

    return CallbackShortcuts(
      bindings: {
        // Esc clears the box first, and goes back when it is already empty.
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_controller.text.isNotEmpty) {
            _clear(vm);
          } else {
            _back();
          }
        },
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(tooltip: 'Back', onPressed: _back, icon: const Icon(Icons.arrow_back_rounded)),
                    Expanded(
                      child: _SearchBox(
                        controller: _controller,
                        focusNode: _focus,
                        onChanged: vm.onQueryChanged,
                        onSubmitted: vm.submit,
                        onClear: () => _clear(vm),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: _body(context, vm),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, SearchViewModel vm) {
    if (vm.isLoading) return const _ResultsSkeleton();
    if (vm.error != null) {
      return StateView(
        icon: Icons.wifi_off_rounded,
        title: AppStrings.genericError,
        message: 'We could not load the videos to search.',
        actionLabel: 'Try again',
        onAction: vm.retry,
      );
    }
    if (!vm.hasCriteria) {
      return _RecentAndCategories(
        vm: vm,
        onPick: (q) {
          _setText(q);
          vm.submit(q);
        },
      );
    }
    return _Results(vm: vm, onClearFilters: vm.clearFilters);
  }
}

/// Rounded search box with a clear button.
class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Search videos and channels',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox(width: 12)
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: onClear,
                    icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Shown while the box is empty: recent searches and the categories.
class _RecentAndCategories extends StatelessWidget {
  const _RecentAndCategories({required this.vm, required this.onPick});

  final SearchViewModel vm;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final categories = vm.categories.where((c) => c != 'All').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (vm.recentQueries.isNotEmpty) ...[
          Row(
            children: [
              Expanded(child: Text('Recent searches', style: theme.textTheme.titleMedium)),
              TextButton(onPressed: vm.clearRecent, child: const Text('Clear all')),
            ],
          ),
          for (final q in vm.recentQueries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.history_rounded, color: scheme.onSurfaceVariant),
              title: Text(q),
              trailing: IconButton(
                tooltip: 'Remove',
                onPressed: () => vm.removeRecent(q),
                icon: Icon(Icons.close_rounded, size: 20, color: scheme.onSurfaceVariant),
              ),
              onTap: () => onPick(q),
            ),
          const SizedBox(height: 20),
        ],
        Text('Browse by category', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in categories) ActionChip(label: Text(c), onPressed: () => vm.setCategory(c)),
          ],
        ),
        if (vm.recentQueries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Text(
              'Type to search. Accents are optional: "hoc" finds "học".',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.vm, required this.onClearFilters});

  final SearchViewModel vm;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wide = context.screenWidth >= Responsive.compactMax;

    final filters = SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: vm.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final c = vm.categories[index];
          final selected = c == vm.category;
          return ChoiceChip(
            label: Text(c),
            selected: selected,
            onSelected: (_) => vm.setCategory(c),
          );
        },
      ),
    );

    final summary = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              vm.results.length == 1 ? '1 video' : '${vm.results.length} videos',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          PopupMenuButton<SearchSort>(
            tooltip: 'Sort by',
            onSelected: vm.setSort,
            itemBuilder: (context) => [
              for (final s in SearchSort.values)
                CheckedPopupMenuItem(value: s, checked: s == vm.sort, child: Text(s.label)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sort: ${vm.sort.label}', style: theme.textTheme.labelLarge),
                  const Icon(Icons.expand_more_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (vm.results.isEmpty && vm.channels.isEmpty) {
      return Column(
        children: [
          filters,
          Expanded(
            child: StateView(
              icon: Icons.search_off_rounded,
              title: AppStrings.noVideos,
              message: vm.query.trim().isEmpty
                  ? 'There is nothing in "${vm.category}" yet.'
                  : 'Nothing matches "${vm.query.trim()}". Check the spelling or try other words.',
              actionLabel: vm.category == 'All' ? null : 'Show all categories',
              onAction: onClearFilters,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        filters,
        summary,
        for (final c in vm.channels)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: ChannelAvatar(name: c.name, size: 48),
            title: Text.rich(SearchService.highlight(
              c.name,
              vm.query,
              theme.textTheme.titleMedium,
              theme.textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800),
            )),
            subtitle: Text(c.videoCount == 1 ? 'Channel, 1 video' : 'Channel, ${c.videoCount} videos'),
            onTap: () {
              vm.commit();
              context.push(RouteNames.channel(c.id));
            },
          ),
        for (final v in vm.results) _VideoResultTile(video: v, query: vm.query, wide: wide, vm: vm),
      ],
    );
  }
}

class _VideoResultTile extends StatelessWidget {
  const _VideoResultTile({required this.video, required this.query, required this.wide, required this.vm});

  final Video video;
  final String query;
  final bool wide;
  final SearchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titleStyle = theme.textTheme.titleMedium;
    final matchStyle = titleStyle?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800);
    final small = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final smallMatch = small?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700);

    return InkWell(
      onTap: () {
        vm.commit();
        context.push(RouteNames.video(video.id), extra: video);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: wide ? 260 : 150,
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: VideoThumbnail(video: video)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    SearchService.highlight(video.title, query, titleStyle, matchStyle),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.compactCount(video.viewCount)} views, ${Formatters.timeAgo(video.createdAt)}',
                    style: small,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ChannelAvatar(name: video.channelName, size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text.rich(
                          SearchService.highlight(video.channelName, query, small, smallMatch),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (wide && video.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(video.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: small),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 150, height: 84, radius: 12),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 14),
                        SizedBox(height: 10),
                        SkeletonBox(width: 140, height: 12),
                        SizedBox(height: 10),
                        SkeletonBox(width: 90, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
