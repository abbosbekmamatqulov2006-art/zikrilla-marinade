import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../state.dart';
import '../ui.dart';

/// Keshbek: balans, kassa uchun raqam, darajalar (tariflar) — hammasi admin paneldan.
class CashbackScreen extends StatelessWidget {
  const CashbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final site = s.site;
    final updated = s.loyaltyUpdatedAt;
    final tiers = site.tiers;
    final current = site.tierById(s.tier) ?? site.tierFor(s.lifetime);
    final next = site.nextTier(s.lifetime);
    final note = site.cashbackNote.of(context);
    final pct = site.cashbackPercent;
    final pctText = pct == pct.roundToDouble() ? pct.round().toString() : pct.toString();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: C.red,
        onRefresh: s.refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
              child: Text(context.t('cashback'), style: tTitle),
            ),

            // ---------- balans ----------
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
                  Text(context.t('points'), style: tsx(16, w: FontWeight.w800, c: C.white)),
                  const SizedBox(height: 6),
                  Text(
                    context.t('cashback_pct', {'n': pctText}),
                    style: tsx(13.5, w: FontWeight.w800, c: const Color(0xEEFFFFFF)),
                  ),
                  if (updated != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      context.t('synced_iiko', {
                        't': '${updated.hour.toString().padLeft(2, '0')}:${updated.minute.toString().padLeft(2, '0')}',
                      }),
                      style: tsx(12.5, w: FontWeight.w700, c: const Color(0xDDFFFFFF)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ---------- kassa uchun raqam ----------
            if (s.user != null && s.user!.phone.isNotEmpty)
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(color: Color(0x14D50C05), shape: BoxShape.circle),
                      child: const Icon(Icons.point_of_sale_rounded, color: C.red),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.user!.phonePretty, style: tsx(20, w: FontWeight.w900, ls: 0.5)),
                          const SizedBox(height: 4),
                          Text(context.t('my_phone_card'), style: tMuted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            // ---------- darajalar ----------
            if (tiers.isNotEmpty)
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.t('tiers'), style: tBlock),
                    const SizedBox(height: 6),
                    Text(
                      next == null
                          ? context.t('tier_max')
                          : context.t('tier_next', {'name': next.name.of(context), 'n': fmt(next.from - s.lifetime)}),
                      style: tsx(14, w: FontWeight.w800, c: C.red),
                    ),
                    if (next != null) ...[
                      const SizedBox(height: 10),
                      ProgressLine(
                        next.from <= 0 ? 1 : (s.lifetime / next.from).clamp(0.0, 1.0).toDouble(),
                        height: 6,
                      ),
                    ],
                    const SizedBox(height: 12),
                    for (final t in tiers)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: t.id == current?.id ? const Color(0x14D50C05) : C.soft,
                            borderRadius: BorderRadius.circular(16),
                            border: t.id == current?.id ? Border.all(color: C.red, width: 1.5) : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                t.id == current?.id ? Icons.workspace_premium_rounded : Icons.workspace_premium_outlined,
                                color: t.id == current?.id ? C.red : C.text3,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.name.of(context), style: tsx(16, w: FontWeight.w900)),
                                    if (t.perks.of(context).isNotEmpty)
                                      Text(t.perks.of(context), style: tMuted),
                                  ],
                                ),
                              ),
                              Text(
                                context.t('from_points', {'n': fmt(t.from)}),
                                style: tsx(12.5, w: FontWeight.w700, c: C.text2),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 14),
              SoftBox(child: Text(note, style: tsx(14.5, w: FontWeight.w600, h: 1.45))),
            ],
          ],
        ),
      ),
    );
  }
}
