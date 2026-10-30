import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../state.dart';
import '../ui.dart';

const languages = [('uz', 'O‘zbekcha', '🇺🇿'), ('ru', 'Русский', '🇷🇺'), ('en', 'English', '🇬🇧')];

class _LanguageOption extends StatelessWidget {
  final String code;
  final String name;
  final String flag;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageOption(this.code, this.name, this.flag, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: AppCard(
      color: selected ? const Color(0x0FD50C05) : C.soft,
      border: Border.all(color: selected ? C.red : Colors.transparent, width: 2),
      onTap: onTap,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(name, style: tsx(17, w: FontWeight.w800)),
          ),
          if (selected) const Icon(Icons.check_circle_rounded, color: C.red),
        ],
      ),
    ),
  );
}

/// First-launch language choice.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSide),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(child: Logo(height: 56)),
              const SizedBox(height: 36),
              Text(context.t('welcome_title'), textAlign: TextAlign.center, style: tTitle),
              const SizedBox(height: 6),
              Text(context.t('choose_language'), textAlign: TextAlign.center, style: tMuted),
              const SizedBox(height: 28),
              for (final (code, name, flag) in languages)
                _LanguageOption(code, name, flag, selected: s.lang == code, onTap: () => s.setLang(code)),
              const Spacer(flex: 2),
              PrimaryButton(context.t('continue'), onTap: () => s.chooseLanguage(s.lang)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

void showLanguageSheet(BuildContext context) {
  final s = context.read<AppState>();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: C.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kSide, 14, kSide, 16),
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
            const SizedBox(height: 18),
            Text(context.tr('choose_language'), style: tBlock),
            const SizedBox(height: 12),
            for (final (code, name, flag) in languages)
              _LanguageOption(
                code,
                name,
                flag,
                selected: s.lang == code,
                onTap: () {
                  s.setLang(code);
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        ),
      ),
    ),
  );
}
