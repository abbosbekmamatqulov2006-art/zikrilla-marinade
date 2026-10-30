import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../l10n.dart';
import '../nav.dart';
import '../state.dart';
import '../ui.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  /// Set from other screens to open the catalog on a category.
  static final pendingCategory = ValueNotifier<Category?>(null);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  Category? category;
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
      return [p.name.uz, p.name.ru, p.name.en, p.ingredients.uz, p.ingredients.ru, p.ingredients.en].any((s) => s.toLowerCase().contains(q));
    }).toList();

    final cats = <(Category?, String)>[
      (null, 'cat_all'),
      (Category.skewers, 'cat_skewers'),
      (Category.minced, 'cat_minced'),
      (Category.chicken, 'cat_chicken'),
      (Category.fish, 'cat_fish'),
      (Category.sets, 'cat_sets'),
      (Category.extras, 'cat_extras'),
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
                        context.t(c.$2),
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
          if (category == null && q.isEmpty && !spicy)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 24),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () {
                    context.read<AppState>().addAll({'lamb': 12, 'chicken': 12, 'sauce': 1, 'coal': 1});
                    toast(context, context.tr('added_to_cart'));
                  },
                  child: Row(
                    children: [
                      const Photo('assets/img/hero_mix.jpg', width: 64, height: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.t('set_banner_title'), style: tsx(16, w: FontWeight.w900)),
                            const SizedBox(height: 3),
                            Text(context.t('set_banner_sub'), style: tMuted),
                            const SizedBox(height: 3),
                            Text(money(context, 332000), style: tsx(15, w: FontWeight.w900)),
                          ],
                        ),
                      ),
                      const Icon(Icons.add_circle_rounded, color: C.red, size: 34),
                    ],
                  ),
                ),
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
                if (!p.isExtra)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: StatusBadge(
                      context.t(p.lowStock ? 'tag_low' : 'tag_in_stock'),
                      kind: p.lowStock ? BadgeKind.white : BadgeKind.green,
                    ),
                  ),
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
                  p.isExtra ? p.subtitle.of(context) : context.t('one_piece_grams'),
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

class ProductScreen extends StatefulWidget {
  final Product p;
  const ProductScreen(this.p, {super.key});
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late int qty = widget.p.isExtra ? 1 : 12;
  bool fav = false;
  int page = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final images = [p.image, 'assets/img/hero_mix.jpg', 'assets/img/step2.jpg'];
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
                        children: [for (final img in images) smartImage(img)],
                      ),
                      const Positioned(left: 12, top: 12, child: CircleBackButton(light: true)),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: CircleIconButton(
                          light: true,
                          icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          iconColor: fav ? C.red : C.black,
                          onTap: () => setState(() => fav = !fav),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < images.length; i++)
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
                  Row(
                    children: [
                      if (p.lowStock) ...[
                        StatusBadge(context.t('tag_low'), kind: BadgeKind.amber),
                        const SizedBox(width: 10),
                      ],
                      const Icon(Icons.star_rounded, size: 18, color: C.text2),
                      const SizedBox(width: 2),
                      Text(
                        '${p.rating} · ${p.reviews} ${context.t('reviews')}',
                        style: tsx(14, w: FontWeight.w700, c: C.text2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(p.name.of(context), style: tsx(30, w: FontWeight.w900, h: 1.1)),
                  const SizedBox(height: 4),
                  Text(
                    p.subtitle.of(context),
                    style: tsx(15, w: FontWeight.w500, c: C.text2),
                  ),
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
                        p.unit != null ? '/ ${p.unit!.of(context)}' : context.t('per_piece'),
                        style: tsx(15, w: FontWeight.w500, c: C.text2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.t('points_back', {'n': fmt(p.points)}),
                    style: tsx(14.5, w: FontWeight.w900, c: C.red),
                  ),
                  if (!p.isExtra) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _InfoPill(context.t('pcs_per_person'))),
                        const SizedBox(width: 10),
                        Expanded(child: _InfoPill(context.t('grill_min', {'n': p.grillMinutes}))),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  SoftBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionLabel(context.t('ingredients')),
                        const SizedBox(height: 8),
                        Text(p.ingredients.of(context), style: tsx(15, w: FontWeight.w500, h: 1.4)),
                        if (!p.isExtra) ...[
                          const SizedBox(height: 8),
                          Text(
                            '✓ ${context.t('no_preservatives')}',
                            style: tsx(14.5, w: FontWeight.w900, c: C.green),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!p.isExtra) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _MetaCard(context.t('marinated'), context.t('today_at', {'t': p.marinatedAt}))),
                        const SizedBox(width: 10),
                        Expanded(child: _MetaCard(context.t('batch'), '№ ${p.batch}')),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: Row(
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
        ),
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

class _MetaCard extends StatelessWidget {
  final String label;
  final String value;
  const _MetaCard(this.label, this.value);
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: 6),
        Text(value, style: tsx(16, w: FontWeight.w900)),
      ],
    ),
  );
}
