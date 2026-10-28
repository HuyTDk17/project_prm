import 'package:flutter/painting.dart';

import '../../../shared/models/video.dart';

enum SearchSort {
  relevance('Relevance'),
  newest('Newest'),
  mostViewed('Most viewed');

  const SearchSort(this.label);
  final String label;
}

/// A channel found by the search (taken from the videos, no extra read).
class ChannelHit {
  const ChannelHit({required this.id, required this.name, required this.ownerId, required this.videoCount});

  final String id;
  final String name;
  final String ownerId;
  final int videoCount;
}

/// Search logic (BR16). Firestore has no full-text search, so the public videos
/// are loaded once and searched in memory:
///  - ignores case and accents ("hoc lap trinh" finds "Học lập trình"),
///  - every word of the query must match (title, channel, category, description),
///  - results are ranked: title start > title word > channel > category > description.
abstract final class SearchService {
  static const _groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };

  static final Map<int, String> _fold = _buildFold();

  static Map<int, String> _buildFold() {
    final map = <int, String>{};
    _groups.forEach((base, chars) {
      for (final rune in chars.runes) {
        map[rune] = base;
      }
    });
    return map;
  }

  /// Lower case and without accents, same length as the input (so matches can
  /// be highlighted in the original text). Combining marks are dropped.
  static String fold(String input) {
    final out = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      if (rune >= 0x300 && rune <= 0x36f) continue;
      out.write(_fold[rune] ?? String.fromCharCode(rune));
    }
    return out.toString();
  }

  /// [fold] with the spaces collapsed and trimmed.
  static String normalize(String input) => fold(input).replaceAll(RegExp(r'\s+'), ' ').trim();

  static bool _wordStart(String text, String token) => text.startsWith(token) || text.contains(' $token');

  /// Ranks [corpus] for [query]. An empty query returns everything in the category.
  static List<Video> search(
    List<Video> corpus,
    String query, {
    String category = 'All',
    SearchSort sort = SearchSort.relevance,
  }) {
    final q = normalize(query);
    final tokens = q.isEmpty ? const <String>[] : q.split(' ');
    final scored = <(Video, int)>[];

    for (final v in corpus) {
      if (category != 'All' && v.categoryName != category) continue;
      if (tokens.isEmpty) {
        scored.add((v, 0));
        continue;
      }
      final title = normalize(v.title);
      final channel = normalize(v.channelName);
      final cat = normalize(v.categoryName);
      final desc = normalize(v.description);
      var score = 0;
      var matchesAll = true;
      for (final t in tokens) {
        var s = 0;
        if (title.contains(t)) s += _wordStart(title, t) ? 30 : 12;
        if (channel.contains(t)) s += _wordStart(channel, t) ? 20 : 8;
        if (cat.contains(t)) s += 6;
        if (desc.contains(t)) s += 2;
        if (s == 0) {
          matchesAll = false;
          break;
        }
        score += s;
      }
      if (!matchesAll) continue;
      if (title.startsWith(q)) {
        score += 60;
      } else if (title.contains(q)) {
        score += 25;
      }
      scored.add((v, score));
    }

    int byNewest(Video a, Video b) => b.createdAt.compareTo(a.createdAt);
    int byViews(Video a, Video b) => b.viewCount.compareTo(a.viewCount);
    scored.sort((a, b) {
      switch (sort) {
        case SearchSort.newest:
          return byNewest(a.$1, b.$1);
        case SearchSort.mostViewed:
          return byViews(a.$1, b.$1);
        case SearchSort.relevance:
          final s = b.$2.compareTo(a.$2);
          if (s != 0) return s;
          final v = byViews(a.$1, b.$1);
          return v != 0 ? v : byNewest(a.$1, b.$1);
      }
    });
    return [for (final item in scored) item.$1];
  }

  /// Channels whose name matches every word of [query].
  static List<ChannelHit> channels(List<Video> corpus, String query) {
    final tokens = normalize(query).split(' ').where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return const [];
    final byId = <String, ChannelHit>{};
    for (final v in corpus) {
      final id = v.channelId;
      if (id == null) continue;
      final name = normalize(v.channelName);
      if (!tokens.every(name.contains)) continue;
      final old = byId[id];
      byId[id] = ChannelHit(
        id: id,
        name: v.channelName,
        ownerId: v.ownerId,
        videoCount: (old?.videoCount ?? 0) + 1,
      );
    }
    final list = byId.values.toList()
      ..sort((a, b) {
        final aStart = normalize(a.name).startsWith(tokens.first) ? 0 : 1;
        final bStart = normalize(b.name).startsWith(tokens.first) ? 0 : 1;
        return aStart != bStart ? aStart.compareTo(bStart) : b.videoCount.compareTo(a.videoCount);
      });
    return list.take(3).toList();
  }

  /// [text] with the parts that match [query] in bold.
  static TextSpan highlight(String text, String query, TextStyle? style, TextStyle? matchStyle) {
    final tokens = normalize(query).split(' ').where((t) => t.isNotEmpty).toList();
    final folded = fold(text);
    if (tokens.isEmpty || folded.length != text.length) return TextSpan(text: text, style: style);

    final marks = List<bool>.filled(text.length, false);
    for (final t in tokens) {
      var from = 0;
      while (true) {
        final i = folded.indexOf(t, from);
        if (i < 0) break;
        for (var k = i; k < i + t.length; k++) {
          marks[k] = true;
        }
        from = i + t.length;
      }
    }

    final spans = <TextSpan>[];
    var start = 0;
    while (start < text.length) {
      var end = start;
      while (end < text.length && marks[end] == marks[start]) {
        end++;
      }
      spans.add(TextSpan(text: text.substring(start, end), style: marks[start] ? matchStyle : style));
      start = end;
    }
    return TextSpan(style: style, children: spans);
  }
}
