import 'package:shared_preferences/shared_preferences.dart';

/// The last searches of this device (kept with shared_preferences).
class RecentSearches {
  static const _key = 'recent_searches';
  static const maxItems = 8;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  Future<List<String>> add(String query) async {
    final clean = query.trim();
    if (clean.length < 2) return load();
    final list = [...await load()]..removeWhere((q) => q.toLowerCase() == clean.toLowerCase());
    list.insert(0, clean);
    if (list.length > maxItems) list.removeRange(maxItems, list.length);
    await _save(list);
    return list;
  }

  Future<List<String>> remove(String query) async {
    final list = [...await load()]..remove(query);
    await _save(list);
    return list;
  }

  Future<void> clear() => _save(const []);

  Future<void> _save(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, list);
  }
}
