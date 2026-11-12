import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart' as hive;

/// Хранилище избранного и локального кэша на базе Hive.
///
/// Импортирует `hive_flutter` с префиксом `hive`, чтобы не конфликтовать с
/// доменной моделью `Box`.
class HiveStorage {
  HiveStorage._(this._favoritesBox, this._cacheBox) : _inMemory = false;

  /// Конструктор для widget-тестов без файлового ввода-вывода внутри FakeAsync.
  HiveStorage.inMemory()
      : _favoritesBox = null,
        _cacheBox = null,
        _inMemory = true;

  static const _favoritesBoxName = 'toidym_favorites';
  static const _cacheBoxName = 'toidym_cache';
  static const _favoriteBoxIdsKey = 'favorite_box_ids';
  static const _cachedBoxesKey = 'cached_boxes_json';

  final hive.Box<dynamic>? _favoritesBox;
  final hive.Box<dynamic>? _cacheBox;
  final bool _inMemory;
  final Map<String, dynamic> _memoryStore = <String, dynamic>{};

  static Future<HiveStorage> init({String? testDirectoryPath}) async {
    if (testDirectoryPath != null) {
      hive.Hive.init(testDirectoryPath);
    } else {
      await hive.Hive.initFlutter();
    }
    final favoritesBox = await hive.Hive.openBox<dynamic>(_favoritesBoxName);
    final cacheBox = await hive.Hive.openBox<dynamic>(_cacheBoxName);
    return HiveStorage._(favoritesBox, cacheBox);
  }

  /// Возвращает множество ID избранных боксов.
  Set<String> getFavoriteBoxIds() {
    final raw = _inMemory
        ? _memoryStore[_favoriteBoxIdsKey]
        : _favoritesBox?.get(_favoriteBoxIdsKey);
    if (raw is List) {
      return raw.map((e) => e.toString()).toSet();
    }
    return <String>{};
  }

  /// Сохраняет обновлённый список избранного.
  Future<void> saveFavoriteBoxIds(Set<String> ids) async {
    final list = ids.toList(growable: false);
    if (_inMemory) {
      _memoryStore[_favoriteBoxIdsKey] = list;
      return;
    }
    await _favoritesBox?.put(_favoriteBoxIdsKey, list);
  }

  /// Переключает признак избранного для [boxId] и возвращает новое состояние.
  Future<Set<String>> toggleFavoriteBoxId(String boxId) async {
    final current = getFavoriteBoxIds();
    if (current.contains(boxId)) {
      current.remove(boxId);
    } else {
      current.add(boxId);
    }
    await saveFavoriteBoxIds(current);
    return current;
  }

  /// Кэширует JSON-список боксов для быстрого старта/офлайн-поддержки.
  Future<void> cacheBoxesJson(List<Map<String, dynamic>> boxesJson) async {
    final encoded = jsonEncode(boxesJson);
    if (_inMemory) {
      _memoryStore[_cachedBoxesKey] = encoded;
      return;
    }
    await _cacheBox?.put(_cachedBoxesKey, encoded);
  }

  /// Возвращает закэшированный JSON-список боксов, если он есть.
  List<Map<String, dynamic>> readCachedBoxesJson() {
    final raw = _inMemory
        ? _memoryStore[_cachedBoxesKey]
        : _cacheBox?.get(_cachedBoxesKey);
    if (raw is! String || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}
