import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../l10n.dart';
import '../nav.dart';
import '../state.dart';
import '../ui.dart';
import 'calculator.dart';
import 'catalog.dart';
import 'group.dart';
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

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pcs = Calc.pieces(adults: people, kids: 0, hours: hours, appetite: 1);
    final coal = Calc.coalKg(pcs);
    final sauce = Calc.sauces(people);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ---------- top bar ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(kSide, 8, kSide, 14),
            child: Row(
              children: [
                const Logo(height: 34),
                const Spacer(),
                CircleIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => toast(context, context.tr('demo_note')),
                ),
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

          // ---------- hero ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSide),
            child: GestureDetector(
              onTap: () => goTab(context, 1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 1.8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset('assets/img/hero_mix.jpg', fit: BoxFit.cover),
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
                            Text(
                              context.t('hero_title').toUpperCase(),
                              style: tsx(24, w: FontWeight.w900, c: C.white, h: 1.05),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.t('hero_sub'),
                              style: tsx(13.5, w: FontWeight.w600, c: C.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ---------- order tracker ----------
          if (s.activeOrder != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSide),
              child: _OrderTracker(
                stage: s.activeOrder!.stage,
                time: context.t('order_number', {'n': s.activeOrder!.number}),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ---------- repeat ----------
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSide),
              child: Text(
                textAlign: TextAlign.center,
                '${itemsText(context, last)}'
                ' · ${money(context, last.entries.fold(0, (a, e) => a + productById(e.key).price * e.value))}',
                style: tsx(13, w: FontWeight.w600, c: C.text2),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ---------- category chips ----------
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: kSide),
              children: [
                for (final (i, c) in [
                  (0, 'cat_skewers'),
                  (1, 'cat_minced'),
                  (2, 'cat_chicken'),
                  (3, 'cat_fish'),
                  (4, 'cat_extras'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: AppChip(
                      context.t(c),
                      selected: i == 0,
                      onTap: () {
                        CatalogScreen.pendingCategory.value = Category.values[i];
                        goTab(context, 1);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---------- mini calculator ----------
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

          // ---------- services ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSide),
            child: Text(context.t('services'), style: tBlock),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSide),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Service(
                        Icons.calculate_rounded,
                        context.t('svc_calc'),
                        () => push(context, const CalculatorScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Service(
                        Icons.menu_book_rounded,
                        context.t('svc_school'),
                        () => push(context, const SchoolScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Service(
                        Icons.groups_rounded,
                        context.t('svc_group'),
                        () => push(context, const GroupOrderScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Service(
                        Icons.lightbulb_rounded,
                        context.t('svc_ideas'),
                        () => push(context, const IdeasScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---------- weekly deals ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSide),
            child: Row(
              children: [
                Expanded(child: Text(context.t('week_deals'), style: tBlock)),
                GestureDetector(
                  onTap: () => goTab(context, 1),
                  child: Text(
                    context.t('see_all'),
                    style: tsx(15, w: FontWeight.w900, c: C.red),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 262,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 8),
              children: [
                for (final p in products.where((p) => p.weeklyDeal))
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(width: 170, child: ProductCard(p)),
                  ),
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

class _Service extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Service(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: Color(0x14D50C05), shape: BoxShape.circle),
            child: Icon(icon, color: C.red, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tsx(13.5, w: FontWeight.w800, h: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}
