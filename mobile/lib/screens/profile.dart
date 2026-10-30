import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../nav.dart';
import '../site.dart';
import '../state.dart';
import '../ui.dart';
import 'auth.dart';
import 'calculator.dart';
import 'contact.dart';
import 'language.dart';
import 'school.dart';
import 'stores.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(kSide, 0, kSide, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
            child: Text(context.t('profile'), style: tTitle),
          ),
          AppCard(
            padding: const EdgeInsets.all(16),
            onTap: () => push(context, const RegisterScreen(edit: true)),
            child: Row(
              children: [
                Avatar(s.user?.initials ?? 'Z', size: 58, red: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.user?.fullName ?? '', style: tsx(18, w: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(s.user?.phonePretty ?? '', style: tMuted),
                    ],
                  ),
                ),
                if (s.site.tierById(s.tier) case final t?) StatusBadge(t.name.of(context)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (s.site.cartMode && s.history.isNotEmpty) ...[
            Text(context.t('order_history'), style: tBlock),
            const SizedBox(height: 12),
          ],
          if (s.site.cartMode)
          for (final o in s.history.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.date,
                            style: tsx(13, w: FontWeight.w600, c: C.text3),
                          ),
                        ),
                        switch (o.status) {
                          'accepted' => StatusBadge(context.t('st_accepted'), kind: BadgeKind.amber),
                          'preparing' => StatusBadge(context.t('st_preparing'), kind: BadgeKind.amber),
                          'ready' => StatusBadge(context.t('st_ready'), kind: BadgeKind.green),
                          _ => StatusBadge(context.t('status_done'), kind: BadgeKind.green),
                        },
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(itemsText(context, o.items), style: tsx(15, w: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(money(context, o.total), style: tsx(17, w: FontWeight.w900)),
                        ),
                        SizedBox(
                          width: 136,
                          child: PrimaryButton(
                            context.t('repeat'),
                            outlined: true,
                            height: 42,
                            onTap: () {
                              s.addAll(o.items);
                              toast(context, context.tr('repeat_added'));
                              s.setTab(2);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          _Menu(
            children: [
              _MenuItem(
                Icons.calculate_outlined,
                context.t('svc_calc'),
                onTap: () => push(context, const CalculatorScreen()),
              ),
              if (s.site.school.isNotEmpty)
                _MenuItem(
                  Icons.menu_book_outlined,
                  context.t('school_title'),
                  onTap: () => push(context, const SchoolScreen()),
                ),
              _MenuItem(
                Icons.call_outlined,
                context.t('order_title'),
                value: s.site.phone,
                onTap: () => showOrderSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Menu(
            children: [
              _MenuItem(
                Icons.badge_outlined,
                context.t('personal_data'),
                onTap: () => push(context, const RegisterScreen(edit: true)),
              ),
              _MenuItem(
                Icons.storefront_outlined,
                context.t('stores'),
                value: s.selectedStore?.name.of(context),
                onTap: () => push(context, const StoresScreen()),
              ),

              _MenuItem(
                Icons.language_rounded,
                context.t('language'),
                value: context.t('lang_name'),
                onTap: () => showLanguageSheet(context),
              ),
              if (s.site.telegramOrder.isNotEmpty)
                _MenuItem(
                  Icons.chat_bubble_outline_rounded,
                  context.t('support'),
                  onTap: () => openLink(s.site.telegramOrder),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const SocialRow(),
          const SizedBox(height: 12),
          _Menu(children: [_MenuItem(Icons.logout_rounded, context.t('logout'), onTap: () => _confirmLogout(context))]),
          const SizedBox(height: 20),
          const Center(child: Logo(height: 28)),
          const SizedBox(height: 6),
          Center(
            child: Text(
              s.backend.isMock ? 'v2.0.0 · test' : 'v2.0.0',
              style: tsx(12, w: FontWeight.w600, c: C.text3),
            ),
          ),
        ],
      ),
    );
  }
}

void _confirmLogout(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: C.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(context.tr('logout_q'), style: tsx(19, w: FontWeight.w900)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            context.tr('cancel'),
            style: tsx(15, w: FontWeight.w800, c: C.text2),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            context.read<AppState>().logout();
          },
          child: Text(
            context.tr('logout'),
            style: tsx(15, w: FontWeight.w900, c: C.red),
          ),
        ),
      ],
    ),
  );
}

class _Menu extends StatelessWidget {
  final List<Widget> children;
  const _Menu({required this.children});
  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const Divider(height: 1, indent: 56, color: C.border),
        ],
      ],
    ),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, {this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: C.black, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: tsx(15.5, w: FontWeight.w700)),
          ),
          if (value != null)
            Text(
              value!,
              style: tsx(14, w: FontWeight.w600, c: C.text3),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: C.text3),
        ],
      ),
    ),
  );
}
