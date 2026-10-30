import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../state.dart';
import '../ui.dart';

class CashbackScreen extends StatelessWidget {
  const CashbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final updated = s.loyaltyUpdatedAt;
    final tiers = ['bronze', 'silver', 'gold'];
    final tierIndex = tiers.indexOf(s.tier).clamp(0, 2);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: C.red,
        onRefresh: s.refreshMe,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
              child: Text(context.t('cashback'), style: tTitle),
            ),

            // ---------- balance ----------
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(color: C.redCard, borderRadius: BorderRadius.circular(26)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(context.t('balance'), color: Colors.white),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: s.points.toDouble()),
                    duration: const Duration(milliseconds: 700),
                    builder: (_, v, _) => Text(
                      fmt(v.round()),
                      style: tsx(54, w: FontWeight.w900, c: C.white, h: 1.05),
                    ),
                  ),
                  Text(
                    context.t('points'),
                    style: tsx(16, w: FontWeight.w800, c: C.white),
                  ),
                  if (updated != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.t('synced_iiko', {
                        't': '${updated.hour.toString().padLeft(2, '0')}:${updated.minute.toString().padLeft(2, '0')}',
                      }),
                      style: tsx(12.5, w: FontWeight.w700, c: const Color(0xDDFFFFFF)),
                    ),
                  ],
                  if (s.backend.isMock) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(color: C.redDark, borderRadius: BorderRadius.circular(14)),
                      child: Text(
                        context.t('expire_note'),
                        style: tsx(14, w: FontWeight.w800, c: C.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ---------- tiers ----------
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < 3; i++)
                        SectionLabel(context.t('tier_${tiers[i]}'), color: i == tierIndex ? C.black : C.text3),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProgressLine(0.1 + tierIndex * 0.45, height: 6),
                  const SizedBox(height: 10),
                  Text(context.t('tier_note'), style: tMuted),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ---------- QR ----------
            AppCard(
              onTap: () => _showQr(context),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: C.border, width: 2),
                    ),
                    child: const FakeQr(size: 66),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.t('qr_title'), style: tsx(16, w: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(context.t('qr_sub'), style: tMuted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---------- tasks ----------
            Text(context.t('tasks'), style: tBlock),
            const SizedBox(height: 12),
            _Task(title: context.t('task_weeks'), badge: context.t('task_weeks_bonus'), done: 2, of: 3),
            const SizedBox(height: 10),
            _Task(title: context.t('task_review'), badge: '+5 000', done: 1, of: 3),
            const SizedBox(height: 14),

            // ---------- Plus ----------
            Container(
              decoration: BoxDecoration(
                color: C.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: C.red, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  const Positioned.fill(child: ZPattern()),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Zikrilla Plus', style: tsx(20, w: FontWeight.w900)),
                            const SizedBox(width: 8),
                            if (s.plus) StatusBadge(context.t('subscribed'), kind: BadgeKind.green),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.t('plus_sub'),
                          style: tsx(14.5, w: FontWeight.w500, c: C.text2),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text('29 000 ${context.t('per_month')}', style: tsx(18, w: FontWeight.w900)),
                            ),
                            SizedBox(
                              width: 140,
                              child: PrimaryButton(
                                s.plus ? context.t('subscribed') : context.t('subscribe'),
                                height: 48,
                                outlined: s.plus,
                                onTap: () {
                                  s.togglePlus();
                                  if (s.plus) toast(context, context.tr('plus_activated'));
                                },
                              ),
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
      ),
    );
  }

  void _showQr(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(9)),
              ),
              const SizedBox(height: 20),
              Text(context.tr('qr_title'), style: tBlock),
              const SizedBox(height: 20),
              const FakeQr(size: 220),
              const SizedBox(height: 16),
              Text('4700 1284 9921', style: tsx(18, w: FontWeight.w900, ls: 2)),
              const SizedBox(height: 6),
              Text(context.tr('qr_sub'), style: tMuted, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _Task extends StatelessWidget {
  final String title;
  final String badge;
  final int done;
  final int of;
  const _Task({required this.title, required this.badge, required this.done, required this.of});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: tsx(16, w: FontWeight.w900)),
            ),
            StatusBadge(badge),
          ],
        ),
        const SizedBox(height: 12),
        ProgressLine(done / of),
        const SizedBox(height: 8),
        Text(context.t('done_of', {'a': done, 'b': of}), style: tMuted),
      ],
    ),
  );
}
