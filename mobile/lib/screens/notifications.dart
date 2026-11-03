import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/backend.dart';
import '../api/models.dart';
import '../data.dart';
import '../l10n.dart';
import '../nav.dart';
import '../site.dart';
import '../state.dart';
import '../ui.dart';
import 'catalog.dart';
import 'school.dart';
import 'stores.dart';

/// Xabarlar qutisi: aksiyalar, yangi mahsulotlar, yangi filiallar, baho so'rovlari.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  /// Ekran ochilgandagi o'qilmaganlar (belgini ko'rsatib turish uchun).
  late final Set<int> _fresh;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    // markInboxSeen() faqat [unread] ni nollaydi, ro'yxatdagi n.unread eskicha qoladi —
    // shuning uchun keshdan faqat hali ko'rilmagan bo'lsa olamiz.
    _fresh = {if (s.unread > 0) for (final n in s.notifications) if (n.unread) n.id};
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await s.loadInbox();
      if (!mounted) return;
      if (s.unread > 0) setState(() => _fresh.addAll([for (final n in s.notifications) if (n.unread) n.id]));
      await s.markInboxSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final items = s.notifications;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: C.red,
          onRefresh: s.loadInbox,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ScreenHeader(context.t('notifications'), back: true),
              if (s.pendingFeedback.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 14),
                  child: AppCard(
                    color: C.amberSoft,
                    onTap: () => showFeedbackSheet(context, s.pendingFeedback.first),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: C.amber, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.t('fb_title'), style: tsx(16, w: FontWeight.w900)),
                              Text(context.t('fb_cta'), style: tMuted),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: C.amber),
                      ],
                    ),
                  ),
                ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(kSide, 60, kSide, 0),
                  child: Column(
                    children: [
                      const Icon(Icons.notifications_none_rounded, size: 56, color: C.text3),
                      const SizedBox(height: 12),
                      Text(context.t('notif_empty'), textAlign: TextAlign.center, style: tMuted),
                    ],
                  ),
                ),
              for (final n in items)
                Padding(
                  padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 10),
                  child: _NotifCard(n, fresh: _fresh.contains(n.id)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification n;
  final bool fresh;
  const _NotifCard(this.n, {required this.fresh});

  IconData get _icon => switch (n.kind) {
    'product' => Icons.new_releases_rounded,
    'store' => Icons.storefront_rounded,
    'feedback' => Icons.star_rounded,
    'system' => Icons.info_rounded,
    _ => Icons.local_offer_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final title = n.title.of(context);
    final body = n.body.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: n.link.isEmpty ? null : () => openAppLink(context, n.link),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (n.image.isNotEmpty) AspectRatio(aspectRatio: 2, child: smartImage(n.image)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(12)),
                  child: Icon(_icon, color: n.kind == 'feedback' ? C.amber : C.red, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(title, style: tsx(15.5, w: FontWeight.w900, h: 1.25))),
                          if (fresh)
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              decoration: const BoxDecoration(color: C.red, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(body, style: tMuted),
                      ],
                      const SizedBox(height: 6),
                      Text(_when(context, n.createdAt), style: tsx(12, w: FontWeight.w600, c: C.text3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _when(BuildContext context, DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 60) return context.t('ago_min', {'n': diff.inMinutes < 1 ? 1 : diff.inMinutes});
  if (diff.inHours < 24) return context.t('ago_h', {'n': diff.inHours});
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year}';
}

/// Xabar / banner havolasini ochadi.
void openAppLink(BuildContext context, String link) {
  final s = context.read<AppState>();
  if (link == 'catalog') {
    goTab(context, 1);
  } else if (link.startsWith('cat:')) {
    CatalogScreen.pendingCategory.value = link.substring(4);
    goTab(context, 1);
  } else if (link.startsWith('product:')) {
    final id = link.substring(8);
    final p = products.where((x) => x.id == id).firstOrNull;
    if (p != null) CatalogScreen.pendingCategory.value = p.category;
    goTab(context, 1);
  } else if (link == 'stores') {
    push(context, const StoresScreen());
  } else if (link == 'school') {
    push(context, const SchoolScreen());
  } else if (link.startsWith('feedback:')) {
    final id = int.tryParse(link.substring(9));
    final f = s.pendingFeedback.where((x) => x.id == id).firstOrNull;
    if (f != null) {
      showFeedbackSheet(context, f);
    } else {
      toast(context, context.tr('fb_already'));
    }
  } else if (link.startsWith('url:') && link.length > 4) {
    openLink(link.substring(4));
  }
}

/// Xariddan keyin: 5 yulduzli baho, ixtiyoriy mahsulot va izoh.
Future<void> showFeedbackSheet(BuildContext context, FeedbackAsk ask) {
  context.read<AppState>().feedbackShown.add(ask.id);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: C.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _FeedbackSheet(ask),
  );
}

class _FeedbackSheet extends StatefulWidget {
  final FeedbackAsk ask;
  const _FeedbackSheet(this.ask);
  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  int rating = 0;
  String? productId;
  final comment = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => sending = true);
    final s = context.read<AppState>();
    try {
      await s.sendFeedback(requestId: widget.ask.id, rating: rating, comment: comment.text, productId: productId);
      if (!mounted) return;
      Navigator.of(context).pop();
      toast(context, context.tr('fb_thanks'));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => sending = false);
      if (e.code == 'already' || e.code == 'not_found') {
        Navigator.of(context).pop();
        toast(context, context.tr('fb_already'));
        await s.loadInbox();
      } else {
        toast(context, e.message ?? context.tr('fb_error'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.ask;
    final where = [
      if (a.store != null) a.store!.of(context),
      if (a.amount > 0) '${fmt(a.amount)} ${context.t('currency')}',
    ].join(' · ');
    final labels = ['', 'fb_r1', 'fb_r2', 'fb_r3', 'fb_r4', 'fb_r5'];
    final sorted = List.of(products)..sort((x, y) => x.name.of(context).compareTo(y.name.of(context)));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
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
              Text(context.t('fb_title'), style: tBlock),
              if (where.isNotEmpty) ...[const SizedBox(height: 4), Text(where, style: tMuted)],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    InkResponse(
                      onTap: () => setState(() => rating = i),
                      radius: 28,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 46,
                          color: i <= rating ? const Color(0xFFF5B301) : C.text3,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(
                height: 24,
                child: Center(
                  child: Text(
                    rating == 0 ? context.t('fb_tap') : context.t(labels[rating]),
                    style: tsx(14, w: FontWeight.w800, c: rating == 0 ? C.text3 : C.black),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                initialValue: productId,
                isExpanded: true,
                decoration: InputDecoration(labelText: context.t('fb_product')),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(context.t('fb_product_none'))),
                  for (final p in sorted)
                    DropdownMenuItem<String?>(
                      value: p.id,
                      child: Text(p.name.of(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => productId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: comment,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: context.t('fb_comment'), alignLabelWithHint: true),
              ),
              const SizedBox(height: 8),
              PrimaryButton(context.t('fb_send'), loading: sending, onTap: rating == 0 || sending ? null : _send),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.t('fb_later'), style: tsx(14, w: FontWeight.w800, c: C.text2)),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        context.read<AppState>().dismissFeedback(a.id);
                        Navigator.of(context).pop();
                      },
                      child: Text(context.t('fb_no'), style: tsx(14, w: FontWeight.w800, c: C.text3)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
