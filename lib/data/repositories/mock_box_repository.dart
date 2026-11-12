import 'dart:async';

import 'package:toidym/core/storage/hive_storage.dart';
import 'package:toidym/core/utils/formatters.dart';
import 'package:toidym/data/mock/seed_data.dart';
import 'package:toidym/domain/repositories/box_repository.dart';
import 'package:toidym/domain/repositories/venue_repository.dart';
import 'package:toidym/domain/rules/business_rules.dart';
import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/box_template.dart';
import 'package:toidym/shared/models/enums.dart';

/// Мок-репозиторий боксов с шаблонами `BoxTemplate`, умной сортировкой и автоархивацией.
class MockBoxRepository implements BoxRepository {
  MockBoxRepository(
    this._hiveStorage,
    this._venueRepository,
  )   : _boxes = SeedData.createBoxes(),
        _templates = SeedData.createTemplates().toList() {
    unawaited(
      _hiveStorage.cacheBoxesJson(
        _boxes.map((b) => b.toJson()).toList(growable: false),
      ),
    );
  }

  final HiveStorage _hiveStorage;
  final VenueRepository _venueRepository;
  final List<Box> _boxes;
  final List<BoxTemplate> _templates;
  final _controller = StreamController<List<Box>>.broadcast();
  bool _shouldFailNextFetch = false;

  void _emit() {
    _controller.add(List<Box>.unmodifiable(_boxes));
    unawaited(
      _hiveStorage.cacheBoxesJson(
        _boxes.map((b) => b.toJson()).toList(growable: false),
      ),
    );
  }

  @override
  void simulateNextFetchError() {
    _shouldFailNextFetch = true;
  }

  @override
  Future<List<Box>> getBoxes({
    AstanaDistrict? district,
    BoxFilterChip filter = BoxFilterChip.all,
    String query = '',
    Set<DietaryPreference> dietaryPreferences = const {},
    BoxSortOption sortOption = BoxSortOption.nearest,
    double? userLat,
    double? userLng,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (_shouldFailNextFetch) {
      _shouldFailNextFetch = false;
      throw Exception('Mock network error while loading boxes');
    }

    final venues = await _venueRepository.getVenues();
    final venueMap = {for (final v in venues) v.id: v};
    final normalizedQuery = query.trim().toLowerCase();

    final filtered = _boxes.where((box) {
      if (box.status == BoxStatus.disabled || box.status == BoxStatus.expired) {
        return false;
      }

      final venue = venueMap[box.venueId];
      if (venue == null || venue.status != VenueStatus.approved) {
        return false;
      }
      if (district != null && venue.district != district) {
        return false;
      }

      switch (filter) {
        case BoxFilterChip.all:
          break;
        case BoxFilterChip.bakery:
          if (box.category != BoxCategory.bakery) return false;
        case BoxFilterChip.hotFood:
          if (box.category != BoxCategory.hotFood) return false;
        case BoxFilterChip.halal:
          if (!box.isHalal) return false;
        case BoxFilterChip.coffee:
          if (box.category != BoxCategory.coffee) return false;
      }

      if (normalizedQuery.isNotEmpty) {
        final inTitle = box.title.toLowerCase().contains(normalizedQuery);
        final inDesc = box.description.toLowerCase().contains(normalizedQuery);
        final inVenue = venue.name.toLowerCase().contains(normalizedQuery);
        if (!inTitle && !inDesc && !inVenue) return false;
      }

      return true;
    }).toList();

    final refLat = userLat ?? AstanaDistrict.esil.centerLat;
    final refLng = userLng ?? AstanaDistrict.esil.centerLng;

    filtered.sort((a, b) {
      // 1. Боксы на срочной перепродаже (Last Minute Resale) всегда на первом месте
      if (a.isLastMinuteResale != b.isLastMinuteResale) {
        return a.isLastMinuteResale ? -1 : 1;
      }

      // 2. Затем — боксы, подходящие под диетические предпочтения
      if (dietaryPreferences.isNotEmpty) {
        final aOk =
            BoxBusinessRules.matchesDietaryPreferences(a, dietaryPreferences);
        final bOk =
            BoxBusinessRules.matchesDietaryPreferences(b, dietaryPreferences);
        if (aOk != bOk) return aOk ? -1 : 1;
      }

      switch (sortOption) {
        case BoxSortOption.nearest:
          final vA = venueMap[a.venueId]!;
          final vB = venueMap[b.venueId]!;
          final dA = AppFormatters.calculateDistanceKm(
            fromLat: refLat,
            fromLng: refLng,
            toLat: vA.lat,
            toLng: vA.lng,
          );
          final dB = AppFormatters.calculateDistanceKm(
            fromLat: refLat,
            fromLng: refLng,
            toLat: vB.lat,
            toLng: vB.lng,
          );
          return dA.compareTo(dB);
        case BoxSortOption.endingSoon:
          return a.pickupWindow.end.compareTo(b.pickupWindow.end);
        case BoxSortOption.maxDiscount:
          return b.discountPercent.compareTo(a.discountPercent);
      }
    });

    return filtered;
  }

  @override
  Stream<List<Box>> watchBoxes() async* {
    yield List<Box>.unmodifiable(_boxes);
    yield* _controller.stream;
  }

  @override
  Future<Box?> getBoxById(String boxId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final box in _boxes) {
      if (box.id == boxId) return box;
    }
    return null;
  }

  @override
  Future<List<Box>> getVenueBoxes(String venueId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _boxes
        .where((b) => b.venueId == venueId)
        .toList(growable: false);
  }

  @override
  Future<Box> createBox(Box box) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final venue = await _venueRepository.getVenueById(box.venueId);
    if (venue == null) {
      throw StateError('Venue not found: ${box.venueId}');
    }

    final violations = BoxBusinessRules.validateNewBox(
      title: box.title,
      description: box.description,
      originalPrice: box.originalPrice,
      discountPrice: box.discountPrice,
      quantity: box.quantity,
      pickupWindow: box.pickupWindow,
      venue: venue,
      markAsHalal: box.isHalal,
    );
    if (violations.isNotEmpty) {
      throw BusinessRuleException(violations);
    }

    final created = box.copyWith(
      id: box.id.isEmpty
          ? 'box_${DateTime.now().millisecondsSinceEpoch}'
          : box.id,
      discountPercent: BoxBusinessRules.calculateDiscountPercent(
        originalPrice: box.originalPrice,
        discountPrice: box.discountPrice,
      ),
      status: box.quantityLeft > 0 ? BoxStatus.active : BoxStatus.soldOut,
    );
    _boxes.insert(0, created);
    _emit();
    return created;
  }

  @override
  Future<Box> updateBoxStock({
    required String boxId,
    required int quantityLeft,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final idx = _boxes.indexWhere((b) => b.id == boxId);
    if (idx == -1) throw StateError('Box not found: $boxId');

    final current = _boxes[idx];
    final safeLeft = quantityLeft.clamp(0, 99);
    final updated = current.copyWith(
      quantityLeft: safeLeft,
      quantity: safeLeft > current.quantity ? safeLeft : current.quantity,
      status: safeLeft == 0
          ? BoxStatus.soldOut
          : (current.status == BoxStatus.disabled ||
                  current.status == BoxStatus.expired
              ? current.status
              : BoxStatus.active),
    );
    _boxes[idx] = updated;
    _emit();
    return updated;
  }

  @override
  Future<Box> toggleBoxStatus({
    required String boxId,
    required BoxStatus status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final idx = _boxes.indexWhere((b) => b.id == boxId);
    if (idx == -1) throw StateError('Box not found: $boxId');

    final current = _boxes[idx];
    final resolvedStatus =
        (status == BoxStatus.active && current.quantityLeft == 0)
            ? BoxStatus.soldOut
            : status;
    final updated = current.copyWith(status: resolvedStatus);
    _boxes[idx] = updated;
    _emit();
    return updated;
  }

  @override
  Future<Box> decrementStock({
    required String boxId,
    required int quantity,
  }) async {
    final idx = _boxes.indexWhere((b) => b.id == boxId);
    if (idx == -1) throw StateError('Box not found: $boxId');
    final current = _boxes[idx];
    final nextLeft =
        (current.quantityLeft - quantity).clamp(0, current.quantity);
    return updateBoxStock(boxId: boxId, quantityLeft: nextLeft);
  }

  @override
  Future<Box> restoreStock({
    required String boxId,
    required int quantity,
  }) async {
    final idx = _boxes.indexWhere((b) => b.id == boxId);
    if (idx == -1) throw StateError('Box not found: $boxId');
    final current = _boxes[idx];
    final nextLeft = (current.quantityLeft + quantity).clamp(0, 99);
    return updateBoxStock(boxId: boxId, quantityLeft: nextLeft);
  }

  @override
  Future<int> archiveExpiredBoxes([DateTime? now]) async {
    final currentTime = now ?? DateTime.now();
    var archivedCount = 0;
    for (var i = 0; i < _boxes.length; i++) {
      final box = _boxes[i];
      if (box.status == BoxStatus.active &&
          box.quantityLeft > 0 &&
          box.pickupWindow.end.isBefore(currentTime)) {
        _boxes[i] = box.copyWith(status: BoxStatus.expired);
        archivedCount++;
      }
    }
    if (archivedCount > 0) _emit();
    return archivedCount;
  }

  @override
  Future<Box> republishExpiredBox({
    required String boxId,
    required PickupWindow pickupWindow,
    required int quantity,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final idx = _boxes.indexWhere((b) => b.id == boxId);
    if (idx == -1) throw StateError('Box not found: $boxId');
    final old = _boxes[idx];
    final updated = old.copyWith(
      pickupWindow: pickupWindow,
      quantity: quantity,
      quantityLeft: quantity,
      status: BoxStatus.active,
      isResale: false,
      createdAt: DateTime.now(),
    );
    _boxes[idx] = updated;
    _emit();
    return updated;
  }

  @override
  Future<Box> requeueForResale({
    required String boxId,
    required int quantityDelta,
    required PickupWindow resaleWindow,
  }) async {
    final idx = _boxes.indexWhere((b) => b.id == boxId);
    if (idx == -1) throw StateError('Box not found: $boxId');
    final old = _boxes[idx];
    final safeDelta = quantityDelta < 1 ? 1 : quantityDelta;
    final nextLeft = (old.quantityLeft + safeDelta).clamp(1, 99);
    final nextTotal = nextLeft > old.quantity ? nextLeft : old.quantity;
    final updated = old.copyWith(
      quantityLeft: nextLeft,
      quantity: nextTotal,
      status: BoxStatus.active,
      isResale: true,
      pickupWindow: resaleWindow,
    );
    _boxes[idx] = updated;
    _emit();
    return updated;
  }

  @override
  Future<List<BoxTemplate>> getVenueTemplates(String venueId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _templates
        .where((t) => t.venueId == venueId)
        .toList(growable: false);
  }

  @override
  Future<BoxTemplate> createTemplate(BoxTemplate template) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _templates.insert(0, template);
    return template;
  }

  @override
  Future<Box> publishFromTemplate({
    required BoxTemplate template,
    required int quantity,
    required PickupWindow pickupWindow,
  }) async {
    final draft = Box(
      id: '',
      venueId: template.venueId,
      title: template.name,
      description: template.description,
      type: template.type,
      category: template.category,
      originalPrice: template.originalPrice,
      discountPrice: template.discountPrice,
      discountPercent: template.discountPercent,
      quantity: quantity,
      quantityLeft: quantity,
      pickupWindow: pickupWindow,
      isHalal: template.isHalal,
      isVegetarian: template.isVegetarian,
      allergens: template.allergens,
      status: BoxStatus.active,
      createdAt: DateTime.now(),
      photos: [template.imageUrl],
    );
    return createBox(draft);
  }
}
