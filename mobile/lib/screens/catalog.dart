import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../l10n.dart';
import '../nav.dart';
import '../site.dart';
import '../state.dart';
import '../ui.dart';
import 'contact.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  /// Set from other screens to open the catalog on a category.
  static final pendingCategory = ValueNotifier<String?>(null);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String? category;
  bool spicy = false;
  String query = '';
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    CatalogScreen.pendingCategory.addListener(_onPending);
  }

  void _onPending() {
    final c = CatalogScreen.pendingCategory.value;
    if (c != null) {
      setState(() => category = c);
      CatalogScreen.pendingCategory.value = null;
    }
  }

  @override
  void dispose() {
    CatalogScreen.pendingCategory.removeListener(_onPending);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final list = products.where((p) {
      if (category != null && p.category != category) return false;
      if (spicy && !p.spicy) return false;
      if (q.isEmpty) return true;
      return [p.name.uz, p.name.ru, p.name.en, p.ingredients.uz, p.ingredients.ru, p.ingredients.en].any((x) => x.toLowerCase().contains(q));
    }).toList();

    final s = context.watch<AppState>();
    final cats = <(String?, String)>[
      (null, context.t('cat_all')),
      ...catalogCategories(context, s.site).where((c) => products.any((p) => p.category == c.$1)),
    ];

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: ScreenHeader(context.t('catalog'))),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSide),
              child: TextField(
                controller: controller,
                onChanged: (v) => setState(() => query = v),
                style: tsx(15, w: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: context.t('search_hint'),
                  hintStyle: tsx(15, w: FontWeight.w500, c: C.text3),
                  prefixIcon: const Icon(Icons.search_rounded, color: C.text3),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, color: C.text3),
                          onPressed: () {
                            controller.clear();
                            setState(() => query = '');
                          },
                        ),
                  filled: true,
                  fillColor: C.soft,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(kSide, 12, kSide, 8),
                children: [
                  for (final c in cats)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(
                        c.$2,
                        selected: category == c.$1,
                        onTap: () => setState(() => category = c.$1),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 14),
              child: Row(
                children: [
                  _OutlineFilter(
                    label: '🌶 ${context.t('filter_spicy')}',
                    active: spicy,
                    onTap: () => setState(() => spicy = !spicy),
                  ),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(context.t('nothing_found'), style: tMuted)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 250,
                ),
                delegate: SliverChildBuilderDelegate((_, i) => ProductCard(list[i]), childCount: list.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _OutlineFilter extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _OutlineFilter({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: active ? const Color(0x14D50C05) : C.white,
    shape: StadiumBorder(side: BorderSide(color: active ? C.red : C.border, width: 1.5)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: tsx(13.5, w: FontWeight.w800, c: active ? C.red : C.black),
        ),
      ),
    ),
  );
}

class ProductCard extends StatelessWidget {
  final Product p;
  const ProductCard(this.p, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final cart = context.select<AppState, bool>((st) => st.site.cartMode);
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => push(context, ProductScreen(p)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 126,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: smartImage(p.image)),
                if (p.lowStock)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: StatusBadge(context.t('tag_low'), kind: BadgeKind.white),
                  ),
                if (cart)
                  Positioned(
                  right: 8,
                  bottom: 8,
                  child: RoundAddButton(
                    onTap: () {
                      s.add(p.id);
                      toast(context, '${p.name.of(context)} — ${context.tr('added_to_cart').toLowerCase()}');
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name.of(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tsx(15, w: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  p.subtitle.of(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tsx(12, w: FontWeight.w500, c: C.text2),
                ),
                const SizedBox(height: 8),
                Text(money(context, p.price), style: tsx(16, w: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  '+${fmt(p.points)} ${context.t('points_short')}',
                  style: tsx(12, w: FontWeight.w900, c: C.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kategoriyalar: panel → Sozlamalar → Kategoriyalar. Server javob bermaguncha — standart ro'yxat.
List<(String, String)> catalogCategories(BuildContext context, SiteConfig site) {
  final fromSite = site.categories;
  if (fromSite.isNotEmpty) return [for (final c in fromSite) (c.id, c.name.of(context))];
  return [
    for (final id in const ['skewers', 'minced', 'chicken', 'fish', 'sets', 'extras']) (id, context.t('cat_$id')),
  ];
}

class ProductScreen extends StatefulWidget {
  final Product p;
  const ProductScreen(this.p, {super.key});
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late int qty = widget.p.isExtra ? 1 : 12;
  int page = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final s = context.watch<AppState>();
    final cart = s.site.cartMode;
    final gallery = p.gallery;
    final desc = p.description?.of(context) ?? '';
    final ingredients = p.ingredients.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: AspectRatio(
                  aspectRatio: 1.35,
                  child: Stack(
                    children: [
                      PageView(
                        onPageChanged: (i) => setState(() => page = i),
                        children: [for (final m in gallery) _MediaPage(m)],
                      ),
                      const Positioned(left: 12, top: 12, child: CircleBackButton(light: true)),
                      if (gallery.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < gallery.length; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: i == page ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: i == page ? 1 : 0.6),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kSide, 16, kSide, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.lowStock || p.spicy || p.weeklyDeal)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (p.weeklyDeal) StatusBadge(context.t('week_deals')),
                          if (p.spicy) StatusBadge('🌶 ${context.t('filter_spicy')}', kind: BadgeKind.amber),
                          if (p.lowStock) StatusBadge(context.t('tag_low'), kind: BadgeKind.amber),
                        ],
                      ),
                    ),
                  Text(p.name.of(context), style: tsx(30, w: FontWeight.w900, h: 1.1)),
                  if (p.subtitle.of(context).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(p.subtitle.of(context), style: tsx(15, w: FontWeight.w500, c: C.text2)),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(money(context, p.price), style: tsx(32, w: FontWeight.w900)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p.unit != null && p.unit!.of(context).isNotEmpty ? '/ ${p.unit!.of(context)}' : context.t('per_piece'),
                        style: tsx(15, w: FontWeight.w500, c: C.text2),
                      ),
                    ],
                  ),
                  if (p.points > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.t('points_back', {'n': fmt(p.points)}),
                      style: tsx(14.5, w: FontWeight.w900, c: C.red),
                    ),
                  ],
                  if (!p.isExtra && p.grillMinutes > 0) ...[
                    const SizedBox(height: 16),
                    _InfoPill(context.t('grill_min', {'n': p.grillMinutes})),
                  ],
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SectionLabel(context.t('description')),
                    const SizedBox(height: 8),
                    Text(desc, style: tsx(15.5, w: FontWeight.w500, h: 1.5)),
                  ],
                  if (ingredients.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SoftBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionLabel(context.t('ingredients')),
                          const SizedBox(height: 8),
                          Text(ingredients, style: tsx(15, w: FontWeight.w500, h: 1.4)),
                        ],
                      ),
                    ),
                  ],
                  if (gallery.any((m) => m.isVideo)) ...[
                    const SizedBox(height: 14),
                    for (final m in gallery.where((m) => m.isVideo))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PrimaryButton(context.t('watch_video'), outlined: true, onTap: () => openLink(m.url)),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: cart
            ? Row(
                children: [
                  QtyStepper(value: qty, min: 1, onChanged: (v) => setState(() => qty = v)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      '${context.t('to_cart')} · ${fmt(p.price * qty)}',
                      onTap: () {
                        context.read<AppState>().add(p.id, qty);
                        toast(context, context.tr('added_to_cart'));
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              )
            : PrimaryButton(context.t('order_now'), onTap: () => showOrderSheet(context)),
      ),
    );
  }
}

/// Galereyadagi bitta sahifa: rasm yoki video muqovasi (bosilsa video ochiladi).
class _MediaPage extends StatelessWidget {
  final MediaItem m;
  const _MediaPage(this.m);

  @override
  Widget build(BuildContext context) {
    if (!m.isVideo) return smartImage(m.url);
    final thumb = youtubeThumb(m.url);
    return GestureDetector(
      onTap: () => openLink(m.url),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumb != null) smartImage(thumb) else const ColoredBox(color: C.black),
          const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 64)),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  const _InfoPill(this.text);
  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: tsx(14.5, w: FontWeight.w800)),
  );
}
