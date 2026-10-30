import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../l10n.dart';
import '../nav.dart';
import '../state.dart';
import '../ui.dart';

/// Portion rules: 4 pcs per adult, 2 per child, +15% for 4h+, 1 kg coal per 12 skewers.
class Calc {
  static const gramsPerPiece = 82.5;

  static int pieces({required int adults, required int kids, required int hours, required double appetite}) {
    var n = (adults * 4 + kids * 2) * appetite;
    if (hours >= 4) n *= 1.15;
    return n.ceil();
  }

  static int coalKg(int pcs) => (pcs / 12).ceil().clamp(1, 999);
  static int sauces(int people) => (people / 5).ceil().clamp(1, 999);

  /// Splits [pcs] across products in even numbers.
  static Map<String, int> split(int pcs, List<String> ids) {
    if (ids.isEmpty) return {};
    final each = ((pcs / ids.length) / 2).ceil() * 2;
    return {for (final id in ids) id: each};
  }
}

class CalculatorScreen extends StatefulWidget {
  final int initialAdults;
  final int initialHours;
  const CalculatorScreen({super.key, this.initialAdults = 6, this.initialHours = 4});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  int mode = 0;
  int event = 0;
  late int adults = widget.initialAdults;
  int kids = 3;
  late int hours = widget.initialHours;
  int appetite = 1;
  double budget = 400000;
  final selected = <String>{'lamb', 'chicken', 'qiyma'};

  static const events = ['ev_picnic', 'ev_friends', 'ev_rest', 'ev_family', 'ev_wedding', 'ev_office', 'ev_catering'];
  static const appetites = [0.8, 1.0, 1.25];

  List<Product> get meats => products.where((p) => !p.isExtra).toList();

  Map<String, int> get plan {
    final ids = meats.where((p) => selected.contains(p.id)).map((p) => p.id).toList();
    if (ids.isEmpty) return {};
    if (mode == 0) {
      return Calc.split(Calc.pieces(adults: adults, kids: kids, hours: hours, appetite: appetites[appetite]), ids);
    }
    final avg = ids.map((id) => productById(id).price).reduce((a, b) => a + b) / ids.length;
    final pcs = ((budget * 0.9) / avg).floor();
    final each = (pcs / ids.length).floor();
    return {for (final id in ids) id: each < 1 ? 1 : each};
  }

  @override
  Widget build(BuildContext context) {
    final p = plan;
    final pcs = p.values.fold(0, (a, b) => a + b);
    final total = p.entries.fold(0, (a, e) => a + productById(e.key).price * e.value);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: [const CircleBackButton(), const Spacer()]),
            ),
            const SizedBox(height: 12),
            Text(context.t('calculator'), style: tTitle),
            const SizedBox(height: 6),
            Text(
              context.t('calc_sub'),
              style: tsx(15, w: FontWeight.w500, c: C.text2),
            ),
            const SizedBox(height: 16),
            SegmentedSwitch(
              labels: [context.t('by_amount'), context.t('by_budget')],
              index: mode,
              onChanged: (i) => setState(() => mode = i),
            ),
            const SizedBox(height: 22),
            SectionLabel(context.t('event_type')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < events.length; i++)
                  AppChip(context.t(events[i]), selected: event == i, onTap: () => setState(() => event = i)),
              ],
            ),
            const SizedBox(height: 22),
            if (mode == 0) ...[
              SectionLabel(context.t('guests')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _Counter(context.t('adults'), adults, 1, (v) => setState(() => adults = v))),
                  const SizedBox(width: 8),
                  Expanded(child: _Counter(context.t('kids'), kids, 0, (v) => setState(() => kids = v))),
                  const SizedBox(width: 8),
                  Expanded(child: _Counter(context.t('hours'), hours, 1, (v) => setState(() => hours = v))),
                ],
              ),
              const SizedBox(height: 22),
              SectionLabel(context.t('appetite')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final (i, k) in [(0, 'app_low'), (1, 'app_mid'), (2, 'app_high')])
                    AppChip(context.t(k), selected: appetite == i, onTap: () => setState(() => appetite = i)),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(child: SectionLabel(context.t('budget_sum'))),
                  Text(fmt(budget.round()), style: tsx(22, w: FontWeight.w900)),
                ],
              ),
              Slider(
                value: budget,
                min: 100000,
                max: 2000000,
                divisions: 38,
                onChanged: (v) => setState(() => budget = v),
              ),
            ],
            const SizedBox(height: 22),
            SectionLabel(context.t('what_to_have')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in meats)
                  AppChip(
                    m.name.of(context),
                    selected: selected.contains(m.id),
                    onTap: () => setState(() => selected.contains(m.id) ? selected.remove(m.id) : selected.add(m.id)),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(context.t('calc_basis')),
                  const SizedBox(height: 8),
                  Text(
                    context.t(mode == 0 ? 'calc_basis_text' : 'calc_basis_budget'),
                    style: tsx(14.5, w: FontWeight.w500, h: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(context.t('total_recommend')),
                      const SizedBox(height: 2),
                      Text(context.t('pcs_skewers', {'n': pcs}), style: tsx(20, w: FontWeight.w900)),
                    ],
                  ),
                ),
                Text(money(context, total), style: tsx(22, w: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              context.t('see_result'),
              onTap: p.isEmpty
                  ? () => toast(context, context.tr('choose_one'))
                  : () => push(
                      context,
                      CalcResultScreen(
                        plan: p,
                        people: mode == 0 ? adults + kids : (pcs / 4).ceil(),
                        hours: hours,
                        eventKey: events[event],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;
  const _Counter(this.label, this.value, this.min, this.onChanged);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
    decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(20)),
    child: Column(
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tsx(11, w: FontWeight.w800, c: C.text3, ls: 1.2),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkResponse(
              onTap: value > min ? () => onChanged(value - 1) : null,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.remove_rounded, size: 20, color: value > min ? C.text3 : C.border),
              ),
            ),
            Text('$value', style: tsx(22, w: FontWeight.w700)),
            InkResponse(
              onTap: () => onChanged(value + 1),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.add_rounded, size: 20, color: C.red),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class CalcResultScreen extends StatefulWidget {
  final Map<String, int> plan;
  final int people;
  final int hours;
  final String eventKey;
  const CalcResultScreen({
    super.key,
    required this.plan,
    required this.people,
    required this.hours,
    required this.eventKey,
  });
  @override
  State<CalcResultScreen> createState() => _CalcResultScreenState();
}

class _CalcResultScreenState extends State<CalcResultScreen> {
  bool coal = true;
  bool sauce = true;

  @override
  Widget build(BuildContext context) {
    final pcs = widget.plan.values.fold(0, (a, b) => a + b);
    final coalKg = Calc.coalKg(pcs);
    final coalPacks = (coalKg / 3).ceil();
    final sauces = Calc.sauces(widget.people);
    final meatTotal = widget.plan.entries.fold(0, (a, e) => a + productById(e.key).price * e.value);
    final coalP = productById('coal');
    final sauceP = productById('sauce');
    final kg = (pcs * Calc.gramsPerPiece / 1000).toStringAsFixed(1);
    final perPerson = (meatTotal / widget.people).round();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 24),
          children: [
            ScreenHeader(context.t('recommendation'), back: true, padding: const EdgeInsets.fromLTRB(0, 12, 0, 16)),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(color: C.redCard, borderRadius: BorderRadius.circular(26)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(
                    context.t('res_head', {'p': widget.people, 'e': context.t(widget.eventKey), 'h': widget.hours}),
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t('res_pcs', {'n': pcs}),
                    style: tsx(48, w: FontWeight.w900, c: C.white, h: 1.05),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t('res_sub', {'kg': kg, 'pp': fmt(perPerson)}),
                    style: tsx(15, w: FontWeight.w800, c: C.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionLabel(context.t('sec_skewers')),
            const SizedBox(height: 10),
            for (final e in widget.plan.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ResultRow(
                  image: productById(e.key).image,
                  title: productById(e.key).name.of(context),
                  subtitle: '${e.value} ${context.t('pcs')} × ${fmt(productById(e.key).price)}',
                  price: productById(e.key).price * e.value,
                ),
              ),
            const SizedBox(height: 12),
            SectionLabel(context.t('sec_extras')),
            const SizedBox(height: 10),
            _ResultRow(
              image: coalP.image,
              title: coalP.name.of(context),
              subtitle: context.t('coal_line', {'n': coalKg}),
              price: coalP.price * coalPacks,
              checked: coal,
              onToggle: () => setState(() => coal = !coal),
            ),
            const SizedBox(height: 10),
            _ResultRow(
              image: sauceP.image,
              title: sauceP.name.of(context),
              subtitle: context.t('sauce_line', {'n': sauces}),
              price: sauceP.price * sauces,
              checked: sauce,
              onToggle: () => setState(() => sauce = !sauce),
            ),
            const SizedBox(height: 14),
            SoftBox(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  StatusBadge(context.t('reminder'), kind: BadgeKind.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(context.t('reminder_text'), style: tsx(14, w: FontWeight.w600, h: 1.35)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: PrimaryButton(
                context.t('to_list'),
                outlined: true,
                onTap: () => toast(context, context.tr('list_saved')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: PrimaryButton(
                context.t('all_to_cart'),
                onTap: () {
                  final s = context.read<AppState>();
                  s.addAll({...widget.plan, if (coal) 'coal': coalPacks, if (sauce) 'sauce': sauces});
                  toast(context, context.tr('added_to_cart'));
                  goTab(context, 2);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final int price;
  final bool? checked;
  final VoidCallback? onToggle;
  const _ResultRow({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.price,
    this.checked,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(12),
    onTap: onToggle,
    child: Row(
      children: [
        Photo(image, width: 56, height: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: tsx(16, w: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tsx(13.5, w: FontWeight.w500, c: C.text2),
              ),
            ],
          ),
        ),
        Text(
          fmt(price),
          style: tsx(
            16,
            w: FontWeight.w900,
            c: checked == false ? C.text3 : C.black,
          ).copyWith(decoration: checked == false ? TextDecoration.lineThrough : null),
        ),
        if (checked != null) ...[
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: checked! ? C.red : C.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: checked! ? C.red : C.border, width: 2),
            ),
            child: checked! ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
          ),
        ],
      ],
    ),
  );
}
