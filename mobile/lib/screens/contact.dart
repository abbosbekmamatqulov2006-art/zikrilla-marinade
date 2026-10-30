import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../nav.dart';
import '../site.dart';
import '../state.dart';
import '../ui.dart';
import 'stores.dart';

/// "Buyurtma" tabi (qo'ng'iroq rejimida): qanday buyurtma berish, operatorlar, Telegram, filiallar, tarmoqlar.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
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
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
              child: Text(context.t('order_title'), style: tTitle),
            ),
            Text(context.t('order_how'), style: tMuted),
            const SizedBox(height: 16),
            const ContactBlock(),
            if (s.stores.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(context.t('stores'), style: tBlock),
              const SizedBox(height: 12),
              for (final st in s.stores)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(st.name.of(context), style: tsx(16, w: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(st.address.of(context), style: tMuted, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(storeStatusText(context, st), style: tsx(12.5, w: FontWeight.w800, c: C.green)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleIconButton(
                          icon: Icons.call_rounded,
                          onTap: () => callPhone(st.phone.isNotEmpty ? st.phone : s.site.phone),
                        ),
                        const SizedBox(width: 8),
                        CircleIconButton(icon: Icons.directions_rounded, onTap: () => openRoute(st)),
                      ],
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => push(context, const StoresScreen()),
                child: Text(context.t('see_all'), style: tsx(15, w: FontWeight.w900, c: C.red)),
              ),
            ],
            const SizedBox(height: 10),
            const SocialRow(),
          ],
        ),
      ),
    );
  }
}

/// Asosiy telefon, operatorlar va Telegram tugmalari.
class ContactBlock extends StatelessWidget {
  const ContactBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<AppState>().site;
    final ops = site.operators;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton('${context.t('call_now')} · ${site.phone}', onTap: () => callPhone(site.phone)),
        if (site.telegramOrder.isNotEmpty) ...[
          const SizedBox(height: 10),
          PrimaryButton(context.t('write_telegram'), outlined: true, onTap: () => openLink(site.telegramOrder)),
        ],
        if (ops.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < ops.length; i++) ...[
                  InkWell(
                    onTap: () => callPhone(ops[i].phone),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.headset_mic_rounded, color: C.red),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ops[i].phone, style: tsx(16, w: FontWeight.w900)),
                                if (ops[i].label.of(context).isNotEmpty)
                                  Text(ops[i].label.of(context), style: tMuted),
                              ],
                            ),
                          ),
                          const Icon(Icons.call_rounded, color: C.text3),
                        ],
                      ),
                    ),
                  ),
                  if (i < ops.length - 1) const Divider(height: 1, indent: 54, color: C.border),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Ijtimoiy tarmoq tugmalari (panelda to'ldirilganlari).
class SocialRow extends StatelessWidget {
  const SocialRow({super.key});

  @override
  Widget build(BuildContext context) {
    final social = context.watch<AppState>().site.social;
    if (social.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t('social'), style: tBlock),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in social.entries)
              ActionChip(
                avatar: Icon(socialIcon(e.key), size: 18, color: C.red),
                label: Text(socialName(e.key), style: tsx(14, w: FontWeight.w800)),
                backgroundColor: C.soft,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                onPressed: () => openLink(e.value),
              ),
          ],
        ),
      ],
    );
  }
}

/// Mahsulot sahifasidan buyurtma: qo'ng'iroq yoki Telegram.
void showOrderSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: C.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kSide, 14, kSide, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(9)),
              ),
            ),
            const SizedBox(height: 16),
            Text(context.tr('order_title'), style: tBlock),
            const SizedBox(height: 6),
            Text(context.tr('order_how'), style: tMuted),
            const SizedBox(height: 16),
            const ContactBlock(),
          ],
        ),
      ),
    ),
  );
}

/// Video kartochkasi: YouTube muqovasi yoki logotip, bosilsa video ochiladi.
class VideoCard extends StatelessWidget {
  final String url;
  final String title;
  final double width;
  const VideoCard({super.key, required this.url, required this.title, this.width = 240});

  @override
  Widget build(BuildContext context) {
    final thumb = youtubeThumb(url);
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () => openLink(url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumb != null)
                      Image.network(
                        thumb,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(color: C.black),
                      )
                    else
                      const ColoredBox(color: C.black),
                    const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 56)),
                  ],
                ),
              ),
            ),
            if (title.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: tsx(14.5, w: FontWeight.w800)),
            ],
          ],
        ),
      ),
    );
  }
}
