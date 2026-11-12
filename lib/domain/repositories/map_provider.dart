/// Поддерживаемые провайдеры карт.
enum MapProviderType {
  osm,
  // TODO: добавить Yandex MapKit при получении API-ключа.
  yandexMapKitTodo,
  // TODO: добавить 2GIS SDK при получении API-ключа.
  twoGisTodo,
}

/// Абстракция провайдера карты для замены OSM на Yandex MapKit / 2GIS без переписывания UI.
abstract interface class MapProvider {
  MapProviderType get type;

  String get tileUrlTemplate;

  String get attributionLabel;

  double get defaultAstanaLat;

  double get defaultAstanaLng;
}
