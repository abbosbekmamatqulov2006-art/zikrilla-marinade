import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../nav.dart';
import '../site.dart';
import '../state.dart';
import '../ui.dart';

/// "Maktab": maqolalar va retseptlar — hammasi admin panel → Ilova → Maktab dan.
class SchoolScreen extends StatelessWidget {
  const SchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.site.school;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: C.red,
          onRefresh: s.loadSite,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ScreenHeader(context.t('school_title'), subtitle: context.t('school_sub'), back: true),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(child: Text(context.t('school_empty'), style: tMuted)),
                ),
              for (final a in list)
                Padding(
                  padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 14),
                  child: ArticleCard(a),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArticleCard extends StatelessWidget {
  final SiteArticle a;
  final double? width;
  const ArticleCard(this.a, {super.key, this.width});

  @override
  Widget build(BuildContext context) {
    final img = a.image.isNotEmpty ? a.image : (youtubeThumb(a.video) ?? '');
    return SizedBox(
      width: width,
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => push(context, ArticleScreen(a)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  smartImage(img),
                  if (a.video.isNotEmpty)
                    const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 52)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title.of(context), maxLines: 2, overflow: TextOverflow.ellipsis, style: tsx(16.5, w: FontWeight.w900)),
                  if (a.minutes > 0) ...[
                    const SizedBox(height: 4),
                    Text(context.t('read_min', {'n': a.minutes}), style: tMuted),
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

class ArticleScreen extends StatelessWidget {
  final SiteArticle a;
  const ArticleScreen(this.a, {super.key});

  @override
  Widget build(BuildContext context) {
    final img = a.image.isNotEmpty ? a.image : (youtubeThumb(a.video) ?? '');
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      smartImage(img),
                      if (a.video.isNotEmpty)
                        Center(
                          child: IconButton(
                            iconSize: 64,
                            icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                            onPressed: () => openLink(a.video),
                          ),
                        ),
                      const Positioned(left: 12, top: 12, child: CircleBackButton(light: true)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kSide, 18, kSide, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title.of(context), style: tsx(26, w: FontWeight.w900, h: 1.15)),
                  if (a.minutes > 0) ...[
                    const SizedBox(height: 6),
                    Text(context.t('read_min', {'n': a.minutes}), style: tMuted),
                  ],
                  const SizedBox(height: 16),
                  SelectableText(a.text.of(context), style: tsx(16, w: FontWeight.w500, h: 1.55)),
                  if (a.video.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    PrimaryButton(context.t('watch_video'), outlined: true, onTap: () => openLink(a.video)),
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
