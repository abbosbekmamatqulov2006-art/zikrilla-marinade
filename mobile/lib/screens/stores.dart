import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/models.dart';
import '../l10n.dart';
import '../location.dart';
import '../state.dart';
import '../ui.dart';

String storeStatusText(BuildContext context, Store s) {
  if (s.is24h) return context.t('open_24h');
  return s.isOpenAt(DateTime.now())
      ? context.t('open_until', {'t': s.close})
      : context.t('closed_opens', {'t': s.open});
}

Future<void> openRoute(Store s) => launchUrl(
  Uri.parse('https://yandex.uz/maps/?rtext=~${s.lat},${s.lng}&rtt=auto'),
  mode: LaunchMode.externalApplication,
);

Future<void> callStore(Store s) => launchUrl(Uri.parse('tel:${s.phone.startsWith('+') ? s.phone : '+${s.phone}'}'));

/// Picks the phone location (for distances) and handles errors with a snackbar.
Future<void> locateForStores(BuildContext context) async {
  try {
    await context.read<AppState>().locate();
  } catch (e) {
    if (context.mounted) showLocationError(context, e);
  }
}

class StoresScreen extends StatefulWidget {
  /// When true, choosing a store pops the screen (used from the cart).
  final bool pickMode;
  const StoresScreen({super.key, this.pickMode = false});
  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  int view = 0; // 0 list, 1 map
  bool locating = false;
  final map = MapController();

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    if (s.stores.isEmpty) s.loadStores();
    if (s.myLocation == null) WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
  }

  Future<void> _locate() async {
    setState(() => locating = true);
    await locateForStores(context);
    if (!mounted) return;
    setState(() => locating = false);
    final p = context.read<AppState>().myLocation;
    if (p != null && view == 1) map.move(LatLng(p.lat, p.lng), 13);
  }

  void _choose(Store store) {
    final s = context.read<AppState>();
    s.selectStore(store.id);
    toast(context, context.tr('store_selected', {'name': store.name.of(context)}));
    if (widget.pickMode) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final sorted = List.of(s.stores);
    if (s.myLocation != null) sorted.sort((a, b) => s.distanceTo(a)!.compareTo(s.distanceTo(b)!));
    final nearest = s.nearestStore;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(context.t('stores'), subtitle: context.t('stores_sub'), back: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedSwitch(
                      labels: [context.t('list_view'), context.t('map_view')],
                      index: view,
                      onChanged: (i) => setState(() => view = i),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: C.soft,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: locating ? null : _locate,
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: locating
                            ? const Padding(
                                padding: EdgeInsets.all(17),
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: C.red),
                              )
                            : const Icon(Icons.my_location_rounded, color: C.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: s.stores.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: C.red))
                  : view == 0
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 24),
                      children: [
                        for (final store in sorted)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StoreCard(
                              store: store,
                              nearest: store.id == nearest?.id,
                              selected: store.id == s.selectedStoreId,
                              distance: s.distanceTo(store),
                              onChoose: () => _choose(store),
                            ),
                          ),
                        if (s.stores.any((x) => x.sample))
                          Center(
                            child: Text(
                              context.t('sample_stores_note'),
                              style: tsx(12.5, w: FontWeight.w600, c: C.text3),
                            ),
                          ),
                      ],
                    )
                  : _StoresMap(controller: map, stores: s.stores, onChoose: _choose),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreCard extends StatelessWidget {
  final Store store;
  final bool nearest;
  final bool selected;
  final double? distance;
  final VoidCallback onChoose;
  const StoreCard({
    super.key,
    required this.store,
    required this.nearest,
    required this.selected,
    required this.distance,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final open = store.isOpenAt(DateTime.now());
    return AppCard(
      border: selected ? Border.all(color: C.red, width: 2) : null,
      padding: const EdgeInsets.all(16),
      onTap: onChoose,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Color(0x14D50C05), shape: BoxShape.circle),
                child: const Icon(Icons.storefront_rounded, color: C.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name.of(context), style: tsx(16.5, w: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      store.address.of(context),
                      style: tsx(13.5, w: FontWeight.w500, c: C.text2),
                    ),
                  ],
                ),
              ),
              if (distance != null) Text(distanceText(context, distance!), style: tsx(15, w: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (nearest) StatusBadge(context.t('nearest'), upper: true),
              if (selected) StatusBadge(context.t('selected'), kind: BadgeKind.green, upper: true),
              StatusBadge(storeStatusText(context, store), kind: open ? BadgeKind.green : BadgeKind.amber),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  selected ? context.t('selected') : context.t('order_here'),
                  height: 44,
                  outlined: selected,
                  onTap: onChoose,
                ),
              ),
              const SizedBox(width: 8),
              _RoundAction(icon: Icons.directions_rounded, tooltip: context.t('route'), onTap: () => openRoute(store)),
              const SizedBox(width: 8),
              _RoundAction(icon: Icons.call_rounded, tooltip: context.t('call'), onTap: () => callStore(store)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundAction({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: C.soft,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: C.black, size: 22)),
      ),
    ),
  );
}

class _StoresMap extends StatelessWidget {
  final MapController controller;
  final List<Store> stores;
  final ValueChanged<Store> onChoose;
  const _StoresMap({required this.controller, required this.stores, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.myLocation;
    final center = me != null ? LatLng(me.lat, me.lng) : const LatLng(41.3111, 69.2797); // Tashkent
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(initialCenter: center, initialZoom: 11.5),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'uz.zikrilla.zikrilla_marinade',
          ),
          MarkerLayer(
            markers: [
              if (me != null)
                Marker(
                  point: LatLng(me.lat, me.lng),
                  width: 22,
                  height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F80ED),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Color(0x552F80ED), blurRadius: 10, spreadRadius: 4)],
                    ),
                  ),
                ),
              for (final store in stores)
                Marker(
                  point: LatLng(store.lat, store.lng),
                  width: 48,
                  height: 56,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => _showStore(context, store),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: store.id == s.selectedStoreId ? C.black : C.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))],
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                        ),
                        CustomPaint(size: const Size(12, 8), painter: _PinTail(store.id == s.selectedStoreId)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
        ],
      ),
    );
  }

  void _showStore(BuildContext context, Store store) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(kSide),
          child: Consumer<AppState>(
            builder: (_, s, _) => StoreCard(
              store: store,
              nearest: store.id == s.nearestStore?.id,
              selected: store.id == s.selectedStoreId,
              distance: s.distanceTo(store),
              onChoose: () {
                Navigator.of(ctx).pop();
                onChoose(store);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PinTail extends CustomPainter {
  final bool dark;
  _PinTail(this.dark);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = dark ? C.black : C.red);
  }

  @override
  bool shouldRepaint(covariant _PinTail old) => old.dark != dark;
}

/// Compact selected-store row used on Home and in the Cart.
class StorePill extends StatelessWidget {
  final VoidCallback onTap;
  const StorePill({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final store = s.selectedStore;
    final d = store == null ? null : s.distanceTo(store);
    return Material(
      color: C.soft,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded, color: C.red, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  store == null
                      ? context.t('choose_store')
                      : '${store.name.of(context)}${d == null ? '' : ' · ${distanceText(context, d)}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tsx(14, w: FontWeight.w800),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: C.text2),
            ],
          ),
        ),
      ),
    );
  }
}
