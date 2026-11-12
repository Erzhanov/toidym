import 'package:toidym/domain/repositories/map_provider.dart';

/// Реализация карты на базе OpenStreetMap без API-ключей.
///
/// // TODO map: добавить реализации для Yandex MapKit и 2GIS SDK за интерфейсом MapProvider.
class OsmMapProvider implements MapProvider {
  const OsmMapProvider();

  @override
  MapProviderType get type => MapProviderType.osm;

  @override
  String get tileUrlTemplate => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  String get attributionLabel => '© OpenStreetMap contributors';

  @override
  double get defaultAstanaLat => 51.1380;

  @override
  double get defaultAstanaLng => 71.4350;
}
