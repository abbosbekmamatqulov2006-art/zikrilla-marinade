import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../nav.dart';
import '../state.dart';
import '../ui.dart';

class _Member {
  final String initials;
  final String name;
  final String itemsKey;
  final int sum;
  final Map<String, int> items;
  bool paid;
  _Member(this.initials, this.name, this.itemsKey, this.sum, this.items, this.paid);
}

class GroupOrderScreen extends StatefulWidget {
  const GroupOrderScreen({super.key});
  @override
  State<GroupOrderScreen> createState() => _GroupOrderScreenState();
}

class _GroupOrderScreenState extends State<GroupOrderScreen> {
  int payMode = 0;
  final members = [
    _Member('AK', 'Aziz', 'g1_items', 160000, {'lamb': 8, 'coal': 1}, true),
    _Member('DS', 'Dilshod', 'g2_items', 48000, {'chicken': 6}, true),
    _Member('NA', 'Nigora', 'g3_items', 52000, {'qiyma': 4, 'sauce': 1}, false),
    _Member('ST', 'Sardor', 'g4_items', 102000, {'virezka': 6}, false),
  ];

  @override
  Widget build(BuildContext context) {
    final total = members.fold(0, (a, m) => a + m.sum);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 24),
          children: [
            ScreenHeader(context.t('group_title'), back: true, padding: const EdgeInsets.fromLTRB(0, 12, 0, 16)),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: C.redCard, borderRadius: BorderRadius.circular(26)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(context.t('group_when'), color: Colors.white),
                  const SizedBox(height: 6),
                  Text(
                    context.t('group_joined', {'n': members.length + 1}),
                    style: tsx(22, w: FontWeight.w900, c: C.white, h: 1.15),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: Stack(
                      children: [
                        for (var i = 0; i < members.length + 1; i++)
                          Positioned(
                            left: i * 32.0,
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: C.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: C.redCard, width: 3),
                              ),
                              child: Text(
                                i < members.length ? members[i].initials : '+1',
                                style: tsx(14, w: FontWeight.w900, c: C.red),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    context.t('send_telegram'),
                    inverted: true,
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'https://zikrilla.uz/g/7KQ2'));
                      toast(context, context.tr('link_copied'));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SoftBox(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  StatusBadge(context.t('deadline'), kind: BadgeKind.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(context.t('deadline_text'), style: tsx(14.5, w: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionLabel(context.t('who_added')),
            const SizedBox(height: 10),
            for (var i = 0; i < members.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => setState(() => members[i].paid = !members[i].paid),
                  child: Row(
                    children: [
                      Avatar(members[i].initials, size: 46),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i == 0 ? '${members[i].name} ${context.t('organizer')}' : members[i].name,
                              style: tsx(16, w: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.t(members[i].itemsKey),
                              style: tsx(13.5, w: FontWeight.w500, c: C.text2),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(fmt(members[i].sum), style: tsx(16, w: FontWeight.w900)),
                          const SizedBox(height: 6),
                          StatusBadge(
                            context.t(members[i].paid ? 'paid' : 'waiting'),
                            kind: members[i].paid ? BadgeKind.green : BadgeKind.amber,
                            upper: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(context.t('payment_method')),
                  const SizedBox(height: 12),
                  SegmentedSwitch(
                    labels: [context.t('each_pays'), context.t('i_pay')],
                    index: payMode,
                    onChanged: (i) => setState(() => payMode = i),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        context.t('group_total'),
                        style: tsx(16, w: FontWeight.w700, c: C.text2),
                      ),
                      const Spacer(),
                      Text(money(context, total), style: tsx(20, w: FontWeight.w900)),
                    ],
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
              flex: 4,
              child: PrimaryButton(
                context.t('remind'),
                outlined: true,
                onTap: () => toast(context, context.tr('reminded')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: PrimaryButton(
                context.t('close_order'),
                onTap: () {
                  final s = context.read<AppState>();
                  for (final m in members) {
                    s.addAll(m.items);
                  }
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
