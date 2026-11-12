import 'package:toidym/shared/models/box.dart';
import 'package:toidym/shared/models/box_template.dart';
import 'package:toidym/shared/models/enums.dart';

/// Интерфейс репозитория боксов, шаблонов (BoxTemplate) и автоархивации.
abstract interface class BoxRepository {
  Future<List<Box>> getBoxes({
    AstanaDistrict? district,
    BoxFilterChip filter = BoxFilterChip.all,
    String query = '',
    Set<DietaryPreference> dietaryPreferences = const {},
    BoxSortOption sortOption = BoxSortOption.nearest,
    double? userLat,
    double? userLng,
  });

  Stream<List<Box>> watchBoxes();

  Future<Box?> getBoxById(String boxId);

  Future<List<Box>> getVenueBoxes(String venueId);

  Future<Box> createBox(Box box);

  Future<Box> updateBoxStock({
    required String boxId,
    required int quantityLeft,
  });

  Future<Box> toggleBoxStatus({
    required String boxId,
    required BoxStatus status,
  });

  Future<Box> decrementStock({
    required String boxId,
    required int quantity,
  });

  Future<Box> restoreStock({
    required String boxId,
    required int quantity,
  });

  /// CRON-автоархивация: боксы с `pickupWindow.end < now && quantityLeft > 0` переходят в EXPIRED.
  Future<int> archiveExpiredBoxes([DateTime? now]);

  /// Перевыставление архивного бокса в 1 нажатие на новое окно.
  Future<Box> republishExpiredBox({
    required String boxId,
    required PickupWindow pickupWindow,
    required int quantity,
  });

  /// Автоматты қайта сату (Resale Worker): қалдық +delta, статус ACTIVE, жаңа Last Minute терезесі.
  Future<Box> requeueForResale({
    required String boxId,
    required int quantityDelta,
    required PickupWindow resaleWindow,
  });

  /// `GET /api/v1/venue/templates`
  Future<List<BoxTemplate>> getVenueTemplates(String venueId);

  Future<BoxTemplate> createTemplate(BoxTemplate template);

  /// `POST /api/v1/venue/boxes/from-template`
  Future<Box> publishFromTemplate({
    required BoxTemplate template,
    required int quantity,
    required PickupWindow pickupWindow,
  });

  void simulateNextFetchError();
}
