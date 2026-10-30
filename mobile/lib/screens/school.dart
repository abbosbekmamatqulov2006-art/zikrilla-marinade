import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../l10n.dart';
import '../nav.dart';
import '../state.dart';
import '../ui.dart';
import 'calculator.dart';

// ============================================================
// School
// ============================================================
class SchoolScreen extends StatefulWidget {
  const SchoolScreen({super.key});
  @override
  State<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends State<SchoolScreen> {
  int filter = 0;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('badge_video', 'card_coal', 'card_coal_meta', 'assets/img/fire_video.jpg', 1, () => _video(context)),
      (
        'badge_guide',
        'card_meat',
        'card_meat_meta',
        'assets/img/plov.jpg',
        3,
        () => push(context, const CalculatorScreen()),
      ),
      ('badge_tip', 'card_store', 'card_store_meta', 'assets/img/qiyma_tray.jpg', 2, () => _video(context)),
      ('badge_video', 'card_chef', 'card_chef_meta', 'assets/img/chef.jpg', 1, () => _video(context)),
    ];
    final tips = [('tip1', 'assets/img/step1.jpg'), ('tip2', 'assets/img/lamb.jpg'), ('tip3', 'assets/img/coal.jpg')];
    // filter: 0 all, 1 videos, 2 tips, 3 recipes
    final visibleCards = cards.where((c) => filter == 0 || c.$5 == filter).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 24),
          children: [
            ScreenHeader(
              context.t('school_title'),
              subtitle: context.t('school_sub'),
              back: true,
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
            ),
            _HeroCard(
              image: 'assets/img/guide_hero.jpg',
              badge: context.t('badge_main_guide'),
              title: context.t('guide_title'),
              meta: context.t('guide_meta'),
              onTap: () => push(context, const GuideScreen()),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (i, k) in [(0, 'f_all'), (1, 'f_videos'), (2, 'f_tips'), (3, 'f_recipes')])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(
                        context.t(k),
                        selected: filter == i,
                        onTap: () {
                          if (i == 3) {
                            push(context, const CommunityScreen());
                          } else {
                            setState(() => filter = i);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                for (final c in visibleCards)
                  AppCard(
                    padding: EdgeInsets.zero,
                    onTap: c.$6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(c.$4, fit: BoxFit.cover),
                              Positioned(left: 10, top: 10, child: StatusBadge(context.t(c.$1), upper: true)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.t(c.$2),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: tsx(14.5, w: FontWeight.w900, h: 1.15),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                context.t(c.$3),
                                style: tsx(12.5, w: FontWeight.w500, c: C.text2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (filter != 1) ...[
              const SizedBox(height: 14),
              for (final tip in tips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Photo(tip.$2, width: 60, height: 60),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionLabel(context.t('tip_label')),
                              const SizedBox(height: 4),
                              Text(context.t(tip.$1), style: tsx(15, w: FontWeight.w900, h: 1.2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _LinkTile(
                    icon: Icons.restaurant_menu_rounded,
                    title: context.t('community'),
                    onTap: () => push(context, const CommunityScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LinkTile(
                    icon: Icons.lightbulb_rounded,
                    title: context.t('ideas'),
                    onTap: () => push(context, const IdeasScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _video(BuildContext context) => toast(context, context.tr('demo_note'));
}

class _HeroCard extends StatelessWidget {
  final String image;
  final String badge;
  final String title;
  final String meta;
  final VoidCallback onTap;
  const _HeroCard({
    required this.image,
    required this.badge,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 2.05,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(image, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xDD000000)],
                  stops: [0.2, 1],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge(badge, upper: true),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: tsx(21, w: FontWeight.w900, c: C.white, h: 1.1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: tsx(13.5, w: FontWeight.w600, c: C.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _LinkTile({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => AppCard(
    color: C.soft,
    onTap: onTap,
    child: Row(
      children: [
        Icon(icon, color: C.red),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: tsx(14, w: FontWeight.w900, h: 1.15)),
        ),
      ],
    ),
  );
}

// ============================================================
// Guide
// ============================================================
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lamb = productById('lamb');
    final steps = [
      ('step1_t', 'step1_d', 'assets/img/step1.jpg'),
      ('step2_t', 'step2_d', 'assets/img/step2.jpg'),
      ('step3_t', 'step3_d', null),
      ('step4_t', 'step4_d', null),
    ];
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            SizedBox(
              height: 300 + top,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/img/guide_hero.jpg', fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x55000000), Colors.transparent, Color(0xDD000000)],
                        stops: [0, 0.35, 1],
                      ),
                    ),
                  ),
                  Positioned(left: kSide, top: top + 12, child: const CircleBackButton(light: true)),
                  Positioned(
                    left: kSide,
                    right: kSide,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusBadge(context.t('badge_guide'), upper: true),
                        const SizedBox(height: 8),
                        Text(
                          context.t('guide_title'),
                          style: tsx(26, w: FontWeight.w900, c: C.white, h: 1.1),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.t('guide_meta2'),
                          style: tsx(14.5, w: FontWeight.w600, c: C.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kSide, 16, kSide, 0),
              child: Column(
                children: [
                  SoftBox(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(999)),
                          child: Text(
                            context.t('important'),
                            style: tsx(12.5, w: FontWeight.w900, c: C.green),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(context.t('guide_important'), style: tsx(14.5, w: FontWeight.w600, h: 1.35)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (var i = 0; i < steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: C.red, shape: BoxShape.circle),
                            child: Text(
                              '${i + 1}',
                              style: tsx(14, w: FontWeight.w900, c: C.white),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.t(steps[i].$1), style: tsx(16.5, w: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text(
                                  context.t(steps[i].$2),
                                  style: tsx(14, w: FontWeight.w500, c: C.text2, h: 1.45),
                                ),
                              ],
                            ),
                          ),
                          if (steps[i].$3 != null) ...[
                            const SizedBox(width: 12),
                            Photo(steps[i].$3!, width: 72, height: 62),
                          ],
                        ],
                      ),
                    ),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionLabel(context.t('fits_guide')),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Photo(lamb.image, width: 56, height: 56),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(lamb.name.of(context), style: tsx(16, w: FontWeight.w900)),
                                  Text(money(context, lamb.price), style: tsx(16, w: FontWeight.w900)),
                                ],
                              ),
                            ),
                            RoundAddButton(
                              size: 44,
                              onTap: () {
                                context.read<AppState>().add('lamb', 4);
                                toast(context, context.tr('added_to_cart'));
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: PrimaryButton(
                  s.guideSaved ? context.t('saved') : context.t('save'),
                  outlined: true,
                  onTap: s.toggleGuideSaved,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(flex: 5, child: PrimaryButton(context.t('start_timer'), onTap: () => _showTimer(context))),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      backgroundColor: C.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _TimerSheet(),
    );
  }
}

class _TimerSheet extends StatefulWidget {
  const _TimerSheet();
  @override
  State<_TimerSheet> createState() => _TimerSheetState();
}

class _TimerSheetState extends State<_TimerSheet> {
  static const total = 12 * 60;
  static const flipEvery = 150;
  int left = total;
  bool running = true;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!running || left == 0) return;
      setState(() => left--);
      if (left % flipEvery == 0 || left == 0) HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String mmss(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final flipIn = left % flipEvery == 0 ? flipEvery : left % flipEvery;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.t('timer_title'), style: tBlock),
            const SizedBox(height: 22),
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 1 - left / total,
                    strokeWidth: 10,
                    color: C.red,
                    backgroundColor: C.soft,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(mmss(left), style: tsx(44, w: FontWeight.w900)),
                        if (left > 0)
                          Text(
                            '${context.t('timer_flip')} ${mmss(flipIn)}',
                            style: tsx(13, w: FontWeight.w700, c: C.text2),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (left == 0)
              Text(
                context.t('timer_done'),
                style: tsx(16, w: FontWeight.w900, c: C.green),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(context.t('stop'), outlined: true, onTap: () => Navigator.of(context).pop()),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    running ? context.t('pause') : context.t('resume'),
                    onTap: left == 0 ? null : () => setState(() => running = !running),
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

// ============================================================
// Community recipes
// ============================================================
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int filter = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final indexed = [for (var i = 0; i < recipes.length; i++) (i, recipes[i])];
    final list = switch (filter) {
      1 => indexed.where((r) => r.$2.isNew).toList(),
      2 => indexed.where((r) => r.$2.type == 'grill').toList(),
      3 => indexed.where((r) => r.$2.type == 'kazan').toList(),
      _ => ([...indexed]..sort((a, b) => b.$2.likes.compareTo(a.$2.likes))),
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 24),
          children: [
            ScreenHeader(
              context.t('community'),
              subtitle: context.t('community_sub'),
              back: true,
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (i, k) in [(0, 'c_popular'), (1, 'c_new'), (2, 'c_grill'), (3, 'c_kazan')])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(context.t(k), selected: filter == i, onTap: () => setState(() => filter = i)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (var j = 0; j < list.length; j++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: j == 0
                    ? _BigRecipe(
                        list[j].$2,
                        liked: s.likedRecipes.contains(list[j].$1),
                        onLike: () => s.toggleLike(list[j].$1),
                      )
                    : _SmallRecipe(
                        list[j].$2,
                        liked: s.likedRecipes.contains(list[j].$1),
                        onLike: () => s.toggleLike(list[j].$1),
                      ),
              ),
            const SizedBox(height: 4),
            SoftBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(context.t('share_too')),
                  const SizedBox(height: 6),
                  Text(context.t('share_reward'), style: tsx(18, w: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(context.t('share_desc'), style: tMuted),
                  const SizedBox(height: 14),
                  PrimaryButton(context.t('upload_recipe'), onTap: () => push(context, const RecipeUploadScreen())),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Like extends StatelessWidget {
  final int count;
  final bool liked;
  final VoidCallback onTap;
  const _Like(this.count, this.liked, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {
      HapticFeedback.selectionClick();
      onTap();
    },
    borderRadius: BorderRadius.circular(9),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: C.red, size: 18),
          const SizedBox(width: 4),
          Text(
            '${count + (liked ? 1 : 0)}',
            style: tsx(15, w: FontWeight.w900, c: C.red),
          ),
        ],
      ),
    ),
  );
}

class _BigRecipe extends StatelessWidget {
  final Recipe r;
  final bool liked;
  final VoidCallback onLike;
  const _BigRecipe(this.r, {required this.liked, required this.onLike});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(r.image, fit: BoxFit.cover),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    '★ ${r.rating}',
                    style: tsx(13, w: FontWeight.w900, c: C.red),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t(r.titleKey), style: tsx(18, w: FontWeight.w900, h: 1.2)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Avatar(r.initials, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.author,
                      style: tsx(14, w: FontWeight.w500, c: C.text2),
                    ),
                  ),
                  _Like(r.likes, liked, onLike),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  AppChip(context.t('minutes', {'n': r.minutes}), dense: true),
                  AppChip(context.t('for_people', {'n': r.people}), dense: true),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SmallRecipe extends StatelessWidget {
  final Recipe r;
  final bool liked;
  final VoidCallback onLike;
  const _SmallRecipe(this.r, {required this.liked, required this.onLike});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Photo(r.image, width: 84, height: 84, radius: 16),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t(r.titleKey), style: tsx(16, w: FontWeight.w900, h: 1.2)),
              const SizedBox(height: 4),
              Text(
                '${r.author} · ${context.t('minutes', {'n': r.minutes})}',
                style: tsx(13.5, w: FontWeight.w500, c: C.text2),
              ),
              const SizedBox(height: 6),
              _Like(r.likes, liked, onLike),
            ],
          ),
        ),
      ],
    ),
  );
}

// ============================================================
// Recipe upload
// ============================================================
class RecipeUploadScreen extends StatefulWidget {
  const RecipeUploadScreen({super.key});
  @override
  State<RecipeUploadScreen> createState() => _RecipeUploadScreenState();
}

class _RecipeUploadScreenState extends State<RecipeUploadScreen> {
  bool media = false;
  final name = TextEditingController();
  String product = 'lamb';
  final time = TextEditingController();
  final ingredients = TextEditingController();
  final steps = <TextEditingController>[TextEditingController()];

  @override
  void dispose() {
    name.dispose();
    time.dispose();
    ingredients.dispose();
    for (final c in steps) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: tsx(15, w: FontWeight.w500, c: C.text3),
    filled: true,
    fillColor: C.soft,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  );

  @override
  Widget build(BuildContext context) {
    final meats = products.where((p) => !p.isExtra).toList();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 24),
          children: [
            ScreenHeader(context.t('upload_recipe'), back: true, padding: const EdgeInsets.fromLTRB(0, 12, 0, 16)),
            GestureDetector(
              onTap: () => setState(() => media = !media),
              child: CustomPaint(
                painter: _DashedBorder(),
                child: Container(
                  height: 160,
                  alignment: Alignment.center,
                  child: media
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Photo('assets/img/plov.jpg', width: 110, height: 110),
                            const SizedBox(width: 14),
                            Text(
                              '✓ ${context.t('media_added')}',
                              style: tsx(15, w: FontWeight.w900, c: C.green),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: C.red, borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                            ),
                            const SizedBox(height: 12),
                            Text(context.t('add_media'), style: tsx(15, w: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(
                              context.t('add_media_sub'),
                              style: tsx(12.5, w: FontWeight.w500, c: C.text2),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SectionLabel(context.t('recipe_name')),
            const SizedBox(height: 8),
            TextField(
              controller: name,
              style: tsx(15, w: FontWeight.w700),
              decoration: _dec(context.t('recipe_name_hint')),
            ),
            const SizedBox(height: 18),
            SectionLabel(context.t('which_product')),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(16)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: product,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  style: tsx(15, w: FontWeight.w700),
                  items: [for (final p in meats) DropdownMenuItem(value: p.id, child: Text(p.name.of(context)))],
                  onChanged: (v) => setState(() => product = v!),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SectionLabel(context.t('cook_time')),
            const SizedBox(height: 8),
            TextField(
              controller: time,
              style: tsx(15, w: FontWeight.w700),
              decoration: _dec(context.t('cook_time_hint')),
            ),
            const SizedBox(height: 18),
            SectionLabel(context.t('composition')),
            const SizedBox(height: 8),
            TextField(
              controller: ingredients,
              minLines: 2,
              maxLines: 5,
              style: tsx(15, w: FontWeight.w700),
              decoration: _dec(context.t('composition_hint')),
            ),
            const SizedBox(height: 18),
            SectionLabel(context.t('steps')),
            const SizedBox(height: 8),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: C.red, shape: BoxShape.circle),
                      child: Text(
                        '${i + 1}',
                        style: tsx(13, w: FontWeight.w900, c: C.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: steps[i],
                        style: tsx(15, w: FontWeight.w700),
                        decoration: _dec(context.t('step_hint')),
                      ),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => steps.add(TextEditingController())),
                icon: const Icon(Icons.add_circle_outline_rounded, color: C.red),
                label: Text(
                  context.t('add_step').toUpperCase(),
                  style: tsx(14, w: FontWeight.w900, c: C.red, ls: 1),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.t('moderation_note'),
              style: tsx(12.5, w: FontWeight.w500, c: C.text2),
            ),
            const SizedBox(height: 10),
            PrimaryButton(context.t('send'), onTap: _submit),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!media || name.text.trim().isEmpty) {
      toast(context, context.tr('fill_required'));
      return;
    }
    FocusScope.of(context).unfocus();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        icon: const Icon(Icons.check_circle_rounded, color: C.green, size: 56),
        title: Text(context.tr('recipe_sent'), style: tsx(20, w: FontWeight.w900)),
        content: Text(context.tr('recipe_sent_sub'), textAlign: TextAlign.center, style: tMuted),
        actions: [
          PrimaryButton(
            context.tr('great'),
            onTap: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22));
    canvas.drawRRect(rrect, Paint()..color = C.soft);
    final paint = Paint()
      ..color = C.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..addRRect(rrect.deflate(1));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// Ideas / suggestions
// ============================================================
class IdeasScreen extends StatefulWidget {
  const IdeasScreen({super.key});
  @override
  State<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen> {
  int filter = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final status = [IdeaStatus.voting, IdeaStatus.review, IdeaStatus.done][filter];
    final list = s.ideas.where((i) => i.status == status).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 24),
          children: [
            ScreenHeader(
              context.t('ideas'),
              subtitle: context.t('ideas_sub'),
              back: true,
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: C.redCard, borderRadius: BorderRadius.circular(26)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('ideas_banner'),
                    style: tsx(20, w: FontWeight.w900, c: C.white, h: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t('ideas_banner_sub'),
                    style: tsx(14, w: FontWeight.w700, c: C.white),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(context.t('suggest'), inverted: true, onTap: () => _suggest(context)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (i, k) in [(0, 's_voting'), (1, 's_accepted'), (2, 's_done')])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(context.t(k), selected: filter == i, onTap: () => setState(() => filter = i)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (final idea in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _IdeaCard(idea, voted: s.voted.contains(idea.id), onVote: () => s.vote(idea)),
              ),
          ],
        ),
      ),
    );
  }

  void _suggest(BuildContext context) {
    final title = TextEditingController();
    final desc = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(kSide, 20, kSide, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('your_idea'), style: tBlock),
              const SizedBox(height: 14),
              TextField(
                controller: title,
                autofocus: true,
                style: tsx(15, w: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: context.tr('idea_title_hint'),
                  filled: true,
                  fillColor: C.soft,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: desc,
                minLines: 2,
                maxLines: 4,
                style: tsx(15, w: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: context.tr('idea_desc_hint'),
                  filled: true,
                  fillColor: C.soft,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                context.tr('send'),
                onTap: () {
                  if (title.text.trim().isEmpty) return;
                  context.read<AppState>().addIdea(
                    title.text.trim(),
                    desc.text.trim(),
                    context.tr('you'),
                    context.tr('today'),
                  );
                  Navigator.of(ctx).pop();
                  setState(() => filter = 0);
                  toast(context, context.tr('idea_sent'));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdeaCard extends StatelessWidget {
  final Idea idea;
  final bool voted;
  final VoidCallback onVote;
  const _IdeaCard(this.idea, {required this.voted, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final (label, kind) = switch (idea.status) {
      IdeaStatus.voting => ('s_voting', BadgeKind.red),
      IdeaStatus.review => ('s_review', BadgeKind.amber),
      IdeaStatus.done => ('s_done', BadgeKind.green),
    };
    final canVote = idea.status == IdeaStatus.voting;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: canVote
                ? () {
                    HapticFeedback.selectionClick();
                    onVote();
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: voted ? C.red : C.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: voted || canVote ? C.red : C.border, width: 2),
              ),
              child: Column(
                children: [
                  Icon(Icons.arrow_drop_up_rounded, size: 26, color: voted ? C.white : (canVote ? C.red : C.text2)),
                  Text(
                    '${idea.votes}',
                    style: tsx(16, w: FontWeight.w900, c: voted ? C.white : (canVote ? C.red : C.black)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(context.t(label), kind: kind, upper: true),
                const SizedBox(height: 8),
                Text(idea.custom ? idea.title : context.t(idea.title), style: tsx(17, w: FontWeight.w900, h: 1.2)),
                if (idea.desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    idea.custom ? idea.desc : context.t(idea.desc),
                    style: tsx(14, w: FontWeight.w500, c: C.text2),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${idea.author} · ${idea.date}',
                  style: tsx(13, w: FontWeight.w500, c: C.text3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
