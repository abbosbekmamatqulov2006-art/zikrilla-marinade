import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../api/models.dart';
import '../l10n.dart';
import '../location.dart';
import '../nav.dart';
import '../state.dart';
import '../ui.dart';
import 'auth.dart';
import 'catalog.dart';
import 'stores.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool placing = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final items = s.cart.entries.toList();

    if (items.isEmpty) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(context.t('cart')),
            const Spacer(),
            Container(
              width: 110,
              height: 110,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: C.soft, shape: BoxShape.circle),
              child: const Icon(Icons.shopping_bag_outlined, size: 50, color: C.text3),
            ),
            const SizedBox(height: 20),
            Text(context.t('cart_empty'), textAlign: TextAlign.center, style: tBlock),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(context.t('cart_empty_sub'), textAlign: TextAlign.center, style: tMuted),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: PrimaryButton(context.t('go_catalog'), onTap: () => s.setTab(1)),
            ),
            const Spacer(flex: 2),
          ],
        ),
      );
    }

    final upsell = products.where((p) => p.isExtra).toList();
    final slots = [for (final x in AppState.slots) x.replaceAll('-', '–')];
    final max = s.maxPoints;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ScreenHeader(context.t('cart')),
          for (final e in items)
            Padding(
              padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 12),
              child: _CartRow(productById(e.key), e.value),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(kSide, 6, kSide, 12),
            child: Text(context.t('add_coal_q'), style: tBlock),
          ),
          SizedBox(
            height: 146,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 10),
              children: [
                for (final p in upsell)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 128,
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        onTap: () {
                          s.add(p.id);
                          toast(context, '${p.name.of(context)} — ${context.tr('added_to_cart').toLowerCase()}');
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                smartImage(p.image, height: 72, width: double.infinity),
                                if (s.qty(p.id) > 0)
                                  Positioned(right: 6, top: 6, child: StatusBadge('×${s.qty(p.id)}')),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name.of(context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tsx(14, w: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(fmt(p.price), style: tsx(14, w: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSide),
            child: SegmentedSwitch(
              labels: [context.t('pickup'), context.t('delivery')],
              index: s.delivery ? 1 : 0,
              onChanged: (i) => s.setDelivery(i == 1),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: kSide),
            child: _StoreRow(),
          ),
          if (s.delivery) const Padding(padding: EdgeInsets.fromLTRB(kSide, 10, kSide, 0), child: _DeliveryAddress()),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: kSide),
              children: [
                for (var i = 0; i < slots.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppChip(
                      slots[i],
                      selected: s.slot == i,
                      disabled: i == 2,
                      onTap: i == 2 ? () => toast(context, context.tr('slot_unavailable')) : () => s.setSlot(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSide),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(context.t('use_points'), style: tsx(16, w: FontWeight.w900)),
                      ),
                      Text(
                        fmt(s.usedPoints),
                        style: tsx(17, w: FontWeight.w900, c: C.red),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context)
                        .copyWith(thumbShape: const _RingThumb(), overlayShape: SliderComponentShape.noOverlay),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Slider(
                        value: s.usedPoints.toDouble(),
                        max: max <= 0 ? 1 : max.toDouble(),
                        divisions: max >= 1000 ? max ~/ 1000 : null,
                        onChanged: max <= 0 ? null : (v) => s.setPointsToUse(v.round()),
                      ),
                    ),
                  ),
                  Text(context.t('points_limit', {'n': fmt(s.points)}), style: tMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSide),
            child: Column(
              children: [
                _SumRow(context.t('products'), fmt(s.cartSubtotal)),
                if (s.delivery)
                  _SumRow(context.t('delivery_fee'), s.deliveryFee == 0 ? context.t('free') : fmt(s.deliveryFee)),
                if (s.usedPoints > 0) _SumRow(context.t('points_line'), '– ${fmt(s.usedPoints)}', color: C.green),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(context.t('total'), style: tsx(18, w: FontWeight.w900)),
                    const Spacer(),
                    Text(money(context, s.cartTotal), style: tsx(28, w: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(context.t('confirm_order'), loading: placing, onTap: _placeOrder),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    final s = context.read<AppState>();
    if (s.selectedStore == null) {
      toast(context, context.tr('choose_store'));
      await push(context, const StoresScreen(pickMode: true));
      return;
    }
    if (s.delivery && (s.effectiveDeliveryAddress?.text.trim().isEmpty ?? true)) {
      toast(context, context.tr('address_required'));
      return;
    }
    final earned = s.earnedPointsFor(s.cart);
    setState(() => placing = true);
    try {
      final order = await s.placeOrder();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          backgroundColor: C.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: C.red, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 16),
                Text(context.tr('order_placed'), style: tsx(22, w: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  context.tr('order_number', {'n': order.number}),
                  style: tsx(16, w: FontWeight.w800, c: C.red),
                ),
                const SizedBox(height: 8),
                Text(context.tr('order_placed_sub', {'n': fmt(earned)}), textAlign: TextAlign.center, style: tMuted),
                const SizedBox(height: 20),
                PrimaryButton(context.tr('great'), onTap: () => Navigator.of(ctx).pop()),
              ],
            ),
          ),
        ),
      );
      if (mounted) goTab(context, 0);
    } catch (e) {
      if (mounted) toast(context, apiErrorText(context, e));
    } finally {
      if (mounted) setState(() => placing = false);
    }
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final store = s.selectedStore;
    final d = store == null ? null : s.distanceTo(store);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => push(context, const StoresScreen(pickMode: true)),
      border: store == null ? Border.all(color: C.red, width: 1.5) : null,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: Color(0x14D50C05), shape: BoxShape.circle),
            child: const Icon(Icons.storefront_rounded, color: C.red, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(context.t('store_label')),
                const SizedBox(height: 2),
                Text(
                  store?.name.of(context) ?? context.t('choose_store'),
                  style: tsx(15.5, w: FontWeight.w900, c: store == null ? C.red : C.black),
                ),
                if (store != null)
                  Text(
                    '${store.address.of(context)}${d == null ? '' : ' · ${distanceText(context, d)}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tsx(13, w: FontWeight.w500, c: C.text2),
                  ),
              ],
            ),
          ),
          Text(
            context.t('change'),
            style: tsx(13.5, w: FontWeight.w900, c: C.red),
          ),
        ],
      ),
    );
  }
}

class _DeliveryAddress extends StatefulWidget {
  const _DeliveryAddress();
  @override
  State<_DeliveryAddress> createState() => _DeliveryAddressState();
}

class _DeliveryAddressState extends State<_DeliveryAddress> {
  late final controller = TextEditingController(text: context.read<AppState>().effectiveDeliveryAddress?.text ?? '');
  bool locating = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _sendLocation() async {
    final s = context.read<AppState>();
    setState(() => locating = true);
    try {
      final p = await LocationService.current();
      final text = await LocationService.addressFor(p, s.lang);
      if (!mounted) return;
      if (text != null) controller.text = text;
      s.setDeliveryAddress(Address(controller.text.trim(), lat: p.lat, lng: p.lng));
      toast(context, context.tr('location_attached'));
    } catch (e) {
      if (mounted) showLocationError(context, e);
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final addr = s.effectiveDeliveryAddress;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(context.t('delivery_address')),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            style: tsx(15, w: FontWeight.w700),
            onChanged: (v) => s.setDeliveryAddress(Address(v.trim(), lat: addr?.lat, lng: addr?.lng)),
            decoration: fieldDecoration(context.t('address_hint')),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                onPressed: locating ? null : _sendLocation,
                icon: locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: C.red),
                      )
                    : const Icon(Icons.near_me_rounded, color: C.red),
                label: Text(
                  context.t('send_location'),
                  style: tsx(14.5, w: FontWeight.w900, c: C.red),
                ),
              ),
              const Spacer(),
              if (addr?.hasCoords == true) StatusBadge('✓ ${context.t('location_attached')}', kind: BadgeKind.green),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final Product p;
  final int qty;
  const _CartRow(this.p, this.qty);

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => s.setQty(p.id, 0),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: C.red, borderRadius: BorderRadius.circular(22)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        onTap: () => push(context, ProductScreen(p)),
        child: Row(
          children: [
            Photo(p.image, width: 58, height: 58),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name.of(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tsx(16, w: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(fmt(p.price * qty), style: tsx(15, w: FontWeight.w900)),
                ],
              ),
            ),
            QtyStepper(value: qty, height: 42, onChanged: (v) => s.setQty(p.id, v)),
          ],
        ),
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SumRow(this.label, this.value, {this.color = C.text2});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(
          label,
          style: tsx(16, w: FontWeight.w600, c: C.text2),
        ),
        const Spacer(),
        Text(
          value,
          style: tsx(16, w: FontWeight.w700, c: color),
        ),
      ],
    ),
  );
}

class _RingThumb extends SliderComponentShape {
  const _RingThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(24, 24);
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final c = context.canvas;
    c.drawCircle(center, 11, Paint()..color = Colors.white);
    c.drawCircle(
      center,
      11,
      Paint()
        ..color = C.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}
