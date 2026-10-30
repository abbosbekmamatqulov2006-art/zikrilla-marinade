import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../l10n.dart';
import '../nav.dart';
import '../state.dart';
import '../ui.dart';
import '../site.dart';
import 'calculator.dart';
import 'catalog.dart';
import 'contact.dart';
import 'school.dart';
import 'stores.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int people = 8;
  int hours = 4;
  int banner = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final site = s.site;
    final pcs = Calc.pieces(adults: people, kids: 0, hours: hours, appetite: 1);
    final coal = Calc.coalKg(pcs);
    final sauce = Calc.sauces(people);
    final ann = site.announcement.of(context);
    final cats = catalogCategories(context, site).where((c) => products.any((p) => p.category == c.$1)).toList();
    final deals = products.where((p) => p.weeklyDeal).toList();
    final school = site.school;
    final videos = site.videos;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: C.red,
        onRefresh: s.refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (ann.isNotEmpty)
              Container(
                width: double.infinity,
                color: C.red,
                padding: const EdgeInsets.symmetric(horizontal: kSide, vertical: 9),
                child: Text(ann, textAlign: TextAlign.center, style: tsx(13.5, w: FontWeight.w800, c: C.white)),
              ),
            // ---------- top bar ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(kSide, 8, kSide, 14),
              child: Row(
                children: [
                  const Logo(height: 34),
                  const Spacer(),
                  CircleIconButton(icon: Icons.call_rounded, onTap: () => callPhone(site.phone)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 14),
              child: Row(
                children: [
                  if (s.user != null && s.user!.firstName.isNotEmpty) ...[
                    Text(context.t('hello', {'name': s.user!.firstName}), style: tsx(18, w: FontWeight.w900)),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: StorePill(onTap: () => push(context, const StoresScreen())),
                    ),
                  ),
                ],
              ),
            ),

            // ---------- bannerlar ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSide),
              child: _Banners(
                site: site,
                page: banner,
                onPage: (i) => setState(() => banner = i),
              ),
            ),
            const SizedBox(height: 14),

            // ---------- buyurtma holati (faqat savat rejimida) ----------
            if (site.cartMode && s.activeOrder != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSide),
                child: _OrderTracker(
                  stage: s.activeOrder!.stage,
                  time: context.t('order_number', {'n': s.activeOrder!.number}),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (site.cartMode)
              if (s.lastOrder case final last?) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kSide),
                  child: PrimaryButton(
                    context.t('repeat_last'),
                    onTap: () {
                      s.addAll(last);
                      toast(context, context.tr('repeat_added'));
                      s.setTab(2);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

            // ---------- qo'ng'iroq / Telegram ----------
            if (!site.cartMode && site.section('contacts')) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSide),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(context.t('call_now'), height: 50, onTap: () => callPhone(site.phone)),
                    ),
                    if (site.telegramOrder.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          'Telegram',
                          height: 50,
                          outlined: true,
                          onTap: () => openLink(site.telegramOrder),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ---------- kategoriyalar ----------
            if (site.section('categories') && cats.isNotEmpty) ...[
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: kSide),
                  children: [
                    for (final c in cats)
                      Padding(
                        padding: const EdgeInsets.only(right: 9),
                        child: AppChip(
                          c.$2,
                          onTap: () {
                            CatalogScreen.pendingCategory.value = c.$1;
                            goTab(context, 1);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ---------- hisoblagich ----------
            if (site.section('calculator')) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSide),
                child: GestureDetector(
                  onTap: () => push(context, CalculatorScreen(initialAdults: people, initialHours: hours)),
                  child: SoftBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: SectionLabel(context.t('calc_label'))),
                            const Icon(Icons.arrow_forward_rounded, size: 20, color: C.text3),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(context.t('calc_q'), style: tsx(20, w: FontWeight.w900)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniCounter(context.t('people'), people, (v) => setState(() => people = v), 1),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: _MiniCounter(context.t('hours'), hours, (v) => setState(() => hours = v), 1)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${context.t('recommend')}: ${context.t('pcs_skewers', {'n': pcs})} · $coal ${context.t('kg_coal')} · $sauce ${context.t('sauces')}',
                          style: tsx(14.5, w: FontWeight.w800, c: C.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
            ],

            // ---------- haftalik aksiyalar ----------
            if (site.section('deals') && deals.isNotEmpty) ...[
              _Head(context.t('week_deals'), onMore: () => goTab(context, 1)),
              SizedBox(
                height: 262,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 8),
                  children: [
                    for (final p in deals)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(width: 170, child: ProductCard(p)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ---------- maktab ----------
            if (site.section('school') && school.isNotEmpty) ...[
              _Head(context.t('school_title'), onMore: () => push(context, const SchoolScreen())),
              SizedBox(
                height: 236,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 10),
                  children: [
                    for (final a in school)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ArticleCard(a, width: 250),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ---------- videolar ----------
            if (site.section('videos') && videos.isNotEmpty) ...[
              _Head(context.t('videos')),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 8),
                  children: [
                    for (final v in videos)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: VideoCard(url: v.url, title: v.title.of(context)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ---------- filiallar ----------
            if (site.section('stores') && s.stores.isNotEmpty) ...[
              _Head(context.t('stores'), onMore: () => push(context, const StoresScreen())),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSide),
                child: Column(
                  children: [
                    for (final st in s.stores.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => push(context, const StoresScreen()),
                          child: Row(
                            children: [
                              const Icon(Icons.storefront_rounded, color: C.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(st.name.of(context), style: tsx(15.5, w: FontWeight.w900)),
                                    Text(storeStatusText(context, st), style: tMuted),
                                  ],
                                ),
                              ),
                              CircleIconButton(
                                icon: Icons.call_rounded,
                                onTap: () => callPhone(st.phone.isNotEmpty ? st.phone : site.phone),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ---------- ijtimoiy tarmoqlar va biz haqimizda ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSide),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SocialRow(),
                  if (site.about.of(context).isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(context.t('about_us'), style: tBlock),
                    const SizedBox(height: 8),
                    Text(site.about.of(context), style: tMuted),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bo'lim sarlavhasi va «Hammasi» havolasi.
class _Head extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;
  const _Head(this.title, {this.onMore});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 12),
    child: Row(
      children: [
        Expanded(child: Text(title, style: tBlock)),
        if (onMore != null)
          GestureDetector(
            onTap: onMore,
            child: Text(context.t('see_all'), style: tsx(15, w: FontWeight.w900, c: C.red)),
          ),
      ],
    ),
  );
}

/// Bosh sahifa slayderi: panel → Ilova → Bannerlar. Bo'sh bo'lsa — Sozlamalar → Bosh sahifa.
class _Banners extends StatelessWidget {
  final SiteConfig site;
  final int page;
  final ValueChanged<int> onPage;
  const _Banners({required this.site, required this.page, required this.onPage});

  @override
  Widget build(BuildContext context) {
    var items = site.banners;
    if (items.isEmpty) {
      final title = lxEmpty(site.heroTitle) ? L(context.t('hero_title'), context.t('hero_title'), context.t('hero_title')) : site.heroTitle;
      final sub = lxEmpty(site.heroSubtitle) ? L(context.t('hero_sub'), context.t('hero_sub'), context.t('hero_sub')) : site.heroSubtitle;
      items = [
        SiteBanner(site.heroImage.isNotEmpty ? site.heroImage : 'assets/img/hero_mix.jpg', title, sub, 'catalog'),
      ];
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1.8,
        child: Stack(
          children: [
            PageView(
              onPageChanged: onPage,
              children: [for (final b in items) _BannerPage(b)],
            ),
            if (items.length > 1)
              Positioned(
                top: 12,
                right: 14,
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: i == page ? 16 : 6,
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
    );
  }
}

class _BannerPage extends StatelessWidget {
  final SiteBanner b;
  const _BannerPage(this.b);

  void _open(BuildContext context) {
    final link = b.link;
    if (link == 'catalog') {
      goTab(context, 1);
    } else if (link.startsWith('cat:')) {
      CatalogScreen.pendingCategory.value = link.substring(4);
      goTab(context, 1);
    } else if (link == 'school') {
      push(context, const SchoolScreen());
    } else if (link.startsWith('url:') && link.length > 4) {
      openLink(link.substring(4));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = b.title.of(context);
    final sub = b.subtitle.of(context);
    return GestureDetector(
      onTap: () => _open(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          smartImage(b.image),
          if (title.isNotEmpty || sub.isNotEmpty)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.35, 1],
                ),
              ),
            ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title.toUpperCase(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: tsx(22, w: FontWeight.w900, c: C.white, h: 1.05),
                  ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tsx(13.5, w: FontWeight.w600, c: C.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTracker extends StatelessWidget {
  final int stage;
  final String time;
  const _OrderTracker({required this.stage, required this.time});

  @override
  Widget build(BuildContext context) {
    final labels = ['st_accepted', 'st_preparing', 'st_ready', 'st_done'];
    return Container(
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: C.red, width: 5)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    layoutBuilder: (current, previous) =>
                        Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
                    child: Text(
                      context.t(stage >= 2 ? 'order_ready_title' : 'order_preparing'),
                      key: ValueKey(stage >= 2),
                      style: tsx(17, w: FontWeight.w900),
                    ),
                  ),
                ),
                StatusBadge(time),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 5,
                      decoration: BoxDecoration(
                        color: i <= stage ? C.red : C.border,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                  if (i < 3) const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: Text(
                      context.t(labels[i]),
                      textAlign: i == 0 ? TextAlign.left : (i == 3 ? TextAlign.right : TextAlign.center),
                      style: tsx(
                        12,
                        w: i == stage ? FontWeight.w800 : FontWeight.w600,
                        c: i == stage ? C.black : C.text3,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCounter extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  const _MiniCounter(this.label, this.value, this.onChanged, this.min);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tsx(14, w: FontWeight.w600, c: C.text2),
            ),
          ),
          InkResponse(
            onTap: value > min ? () => onChanged(value - 1) : null,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.remove_rounded, size: 18, color: value > min ? C.text2 : C.border),
            ),
          ),
          SizedBox(
            width: 26,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: tsx(20, w: FontWeight.w700),
            ),
          ),
          InkResponse(
            onTap: () => onChanged(value + 1),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.add_rounded, size: 18, color: C.red),
            ),
          ),
        ],
      ),
    );
  }
}
