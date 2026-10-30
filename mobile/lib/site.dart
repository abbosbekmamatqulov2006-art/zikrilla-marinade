import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api/backend.dart' show apiUrl;
import 'l10n.dart';

/// Server /settings dagi {uz, ru, en} -> L.
L lx(dynamic j) {
  final m = j is Map ? j : const {};
  String s(String k) => (m[k] ?? '').toString();
  final uz = s('uz'), ru = s('ru'), en = s('en');
  final base = uz.isNotEmpty ? uz : (ru.isNotEmpty ? ru : en);
  return L(ru.isNotEmpty ? ru : base, en.isNotEmpty ? en : base, uz.isNotEmpty ? uz : base);
}

bool lxEmpty(L l) => l.uz.isEmpty && l.ru.isEmpty && l.en.isEmpty;

List<Map<String, dynamic>> _maps(dynamic v) =>
    v is List ? [for (final x in v) if (x is Map) Map<String, dynamic>.from(x)] : const [];

int _int(dynamic v, [int d = 0]) => v is num ? v.round() : int.tryParse('$v') ?? d;

class SiteOperator {
  final L label;
  final String phone;
  const SiteOperator(this.label, this.phone);
}

class SiteCategory {
  final String id;
  final L name;
  const SiteCategory(this.id, this.name);
}

class SiteVideo {
  final L title;
  final String url;
  const SiteVideo(this.title, this.url);
}

class SiteTier {
  final String id;
  final int from;
  final L name;
  final L perks;
  const SiteTier(this.id, this.from, this.name, this.perks);
}

class SiteBanner {
  final String image;
  final L title;
  final L subtitle;
  final String link; // catalog | cat:<id> | school | url:https://...
  const SiteBanner(this.image, this.title, this.subtitle, this.link);
}

class SiteArticle {
  final String id;
  final L title;
  final L text;
  final String image;
  final String video;
  final int minutes;
  const SiteArticle(this.id, this.title, this.text, this.image, this.video, this.minutes);
}

/// Admin paneldagi barcha sozlamalar. Server javob bermasa — ilova ichidagi standart qiymatlar.
class SiteConfig {
  final Map<String, dynamic> raw;
  SiteConfig(this.raw);
  factory SiteConfig.empty() => SiteConfig(const {});

  Map<String, dynamic> get _app => raw['app'] is Map ? Map<String, dynamic>.from(raw['app'] as Map) : const {};
  Map<String, dynamic> get _cb =>
      raw['cashback'] is Map ? Map<String, dynamic>.from(raw['cashback'] as Map) : const {};

  // ---------- aloqa ----------
  String get phone => (raw['phone'] ?? '+998783337272').toString();
  String get telegramOrder => (raw['telegramOrder'] ?? '').toString();
  List<SiteOperator> get operators => [
    for (final o in _maps(raw['operators']))
      if ('${o['phone'] ?? ''}'.trim().isNotEmpty) SiteOperator(lx(o['label']), '${o['phone']}'.trim()),
  ];
  Map<String, String> get social {
    final m = raw['social'] is Map ? raw['social'] as Map : const {};
    return {
      for (final k in const ['instagram', 'telegram', 'youtube', 'facebook', 'tiktok'])
        if ('${m[k] ?? ''}'.trim().isNotEmpty) k: '${m[k]}'.trim(),
    };
  }

  // ---------- kontent ----------
  L get heroTitle => lx((raw['hero'] as Map?)?['title']);
  L get heroSubtitle => lx((raw['hero'] as Map?)?['subtitle']);
  String get heroImage => ((raw['hero'] as Map?)?['image'] ?? '').toString();
  L get announcement => lx(raw['announcement']);
  L get about => lx(raw['about']);
  List<SiteVideo> get videos => [
    for (final v in _maps(raw['videos']))
      if ('${v['url'] ?? ''}'.isNotEmpty) SiteVideo(lx(v['title']), '${v['url']}'),
  ];
  List<SiteCategory> get categories => [
    for (final c in _maps(raw['categories']))
      if ('${c['id'] ?? ''}'.isNotEmpty) SiteCategory('${c['id']}', lx(c['name'])),
  ];

  // ---------- keshbek ----------
  double get cashbackPercent => (_cb['percent'] as num?)?.toDouble() ?? 5;
  int get maxShare => _int(_cb['maxShare'], 30);
  L get cashbackNote => lx(_cb['note']);
  List<SiteTier> get tiers {
    final list = [
      for (final t in _maps(_cb['tiers']))
        if ('${t['id'] ?? ''}'.isNotEmpty) SiteTier('${t['id']}', _int(t['from']), lx(t['name']), lx(t['perks'])),
    ]..sort((a, b) => a.from.compareTo(b.from));
    return list;
  }

  SiteTier? tierById(String id) => tiers.where((t) => t.id == id).firstOrNull;

  /// Jami yig'ilgan ballga qarab daraja (server ham shunday hisoblaydi).
  SiteTier? tierFor(int lifetime) {
    SiteTier? best;
    for (final t in tiers) {
      if (lifetime >= t.from) best = t;
    }
    return best;
  }

  SiteTier? nextTier(int lifetime) => tiers.where((t) => t.from > lifetime).firstOrNull;

  // ---------- ilova ----------
  /// true — ilovada savat va buyurtma; false — qo'ng'iroq/Telegram orqali (standart).
  bool get cartMode => _app['ordering'] == 'cart';

  bool section(String key) {
    final m = _app['sections'];
    if (m is Map && m[key] is bool) return m[key] as bool;
    return true;
  }

  List<SiteBanner> get banners => [
    for (final b in _maps(_app['banners'])) SiteBanner('${b['image'] ?? ''}', lx(b['title']), lx(b['subtitle']), '${b['link'] ?? ''}'),
  ];

  List<SiteArticle> get school => [
    for (final a in _maps(_app['school']))
      if (!lxEmpty(lx(a['title'])))
        SiteArticle(
          '${a['id'] ?? ''}',
          lx(a['title']),
          lx(a['text']),
          '${a['image'] ?? ''}',
          '${a['video'] ?? ''}',
          _int(a['minutes']),
        ),
  ];
}

// =====================================================================
// Tashqi havolalar: qo'ng'iroq, Telegram, video, sayt
// =====================================================================
String fullUrl(String path) => path.startsWith('http') ? path : '$apiUrl$path';

/// Havolani tashqi ilovada ochadi (YouTube, Instagram, Telegram, brauzer). Xato bo'lsa jim o'tadi.
Future<void> openLink(String url) async {
  if (url.trim().isEmpty) return;
  try {
    await launchUrl(Uri.parse(fullUrl(url.trim())), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

Future<void> callPhone(String phone) async {
  final p = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (p.isEmpty) return;
  try {
    await launchUrl(Uri.parse('tel:${p.startsWith('+') ? p : '+$p'}'));
  } catch (_) {}
}

/// YouTube havolasidan muqova rasmi (bo'lmasa null).
String? youtubeThumb(String url) {
  final m = RegExp(r'(?:youtu\.be/|v=|shorts/|embed/)([\w-]{11})').firstMatch(url);
  return m == null ? null : 'https://img.youtube.com/vi/${m.group(1)}/hqdefault.jpg';
}

IconData socialIcon(String key) => switch (key) {
  'telegram' => Icons.send_rounded,
  'youtube' => Icons.play_circle_fill_rounded,
  'facebook' => Icons.facebook,
  'instagram' => Icons.camera_alt_rounded,
  _ => Icons.public_rounded,
};

String socialName(String key) => switch (key) {
  'instagram' => 'Instagram',
  'telegram' => 'Telegram',
  'youtube' => 'YouTube',
  'facebook' => 'Facebook',
  'tiktok' => 'TikTok',
  _ => key,
};
