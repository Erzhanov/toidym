import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'ui.dart';

class NearbyMap extends StatefulWidget {
  const NearbyMap({
    super.key,
    required this.boxes,
    required this.district,
    required this.selectedCard,
  });
  final List<FoodBox> boxes;
  final int district;
  final Widget Function(FoodBox box) selectedCard;
  @override
  State<NearbyMap> createState() => _NearbyMapState();
}

class _NearbyMapState extends State<NearbyMap> {
  String? selectedId;
  bool tileFailed = false;

  @override
  Widget build(BuildContext context) {
    final (lat, lng) = districtPoints[widget.district];
    final selected = widget.boxes
        .where((box) => box.id == selectedId)
        .firstOrNull;
    // A venue can publish several boxes at the same address.
    final groups = <(double, double), List<FoodBox>>{};
    for (final box in widget.boxes) {
      (groups[(box.lat, box.lng)] ??= []).add(box);
    }
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(lat, lng),
                      initialZoom: 13.9,
                      minZoom: 10,
                      maxZoom: 18,
                      backgroundColor: pale,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onTap: (_, _) => setState(() => selectedId = null),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'kz.toidym.toidym',
                        maxNativeZoom: 19,
                        panBuffer: 0,
                        errorTileCallback: (_, _, _) {
                          if (!tileFailed && mounted) {
                            setState(() => tileFailed = true);
                          }
                        },
                      ),
                      MarkerLayer(
                        markers: [
                          for (final items in groups.values)
                            Marker(
                              point: LatLng(items.first.lat, items.first.lng),
                              width: 105,
                              height: 52,
                              child: Center(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    minimumSize: const Size(0, 40),
                                    backgroundColor: items.contains(selected)
                                        ? yellow
                                        : ink,
                                    foregroundColor: items.contains(selected)
                                        ? ink
                                        : cream,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (items.length == 1) {
                                      setState(
                                        () => selectedId = items.first.id,
                                      );
                                      return;
                                    }
                                    final id =
                                        await showModalBottomSheet<String>(
                                          context: context,
                                          showDragHandle: true,
                                          builder: (context) => SafeArea(
                                            child: ListView(
                                              shrinkWrap: true,
                                              children: [
                                                for (final box in items)
                                                  ListTile(
                                                    title: Text(
                                                      context.boxTitle(box),
                                                    ),
                                                    trailing: Text(
                                                      money(box.price),
                                                    ),
                                                    onTap: () => Navigator.pop(
                                                      context,
                                                      box.id,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                    if (id != null && mounted) {
                                      setState(() => selectedId = id);
                                    }
                                  },
                                  child: Text(
                                    money(
                                      items
                                          .map((b) => b.price)
                                          .reduce((a, b) => a < b ? a : b),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SimpleAttributionWidget(
                        source: const Text('OpenStreetMap contributors'),
                        onTap: () => launchUrl(
                          Uri.https('www.openstreetmap.org', '/copyright'),
                        ),
                      ),
                    ],
                  ),
                  if (tileFailed)
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Tag(
                          context.tr(
                            'Часть карты недоступна',
                            'Картаның бір бөлігі қолжетімсіз',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
            child: widget.selectedCard(selected),
          )
        else
          Padding(
            padding: const EdgeInsets.all(9),
            child: Text(
              widget.boxes.isEmpty
                  ? context.tr(
                      'Нет боксов по выбранным фильтрам',
                      'Таңдалған сүзгі бойынша бокс жоқ',
                    )
                  : context.tr(
                      'Нажмите на цену, чтобы открыть бокс',
                      'Боксты ашу үшін бағасын басыңыз',
                    ),
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
