import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n.dart';
import 'screens/auth.dart';
import 'screens/cart.dart';
import 'screens/cashback.dart';
import 'screens/catalog.dart';
import 'screens/contact.dart';
import 'screens/home.dart';
import 'screens/language.dart';
import 'screens/profile.dart';
import 'state.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const ZikrillaApp()));
}

class ZikrillaApp extends StatelessWidget {
  const ZikrillaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.select<AppState, String>((s) => s.lang);
    return MaterialApp(
      title: 'Zikrilla Marinade',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: Locale(lang),
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => _WebPhoneFrame(child: child!),
      home: const AuthGate(),
    );
  }
}

/// Routes between language choice, login, registration and the main app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AppState, AuthStatus>((s) => s.status);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: switch (status) {
        AuthStatus.loading => const Scaffold(
          key: ValueKey('loading'),
          body: Center(child: Logo(height: 56)),
        ),
        AuthStatus.chooseLanguage => const LanguageScreen(key: ValueKey('lang')),
        AuthStatus.loggedOut => const PhoneScreen(key: ValueKey('phone')),
        AuthStatus.needsProfile => const RegisterScreen(key: ValueKey('register')),
        AuthStatus.ready => const RootShell(key: ValueKey('app')),
      },
    );
  }
}

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cartMode = state.site.cartMode;
    final pages = [
      const HomeScreen(),
      const CatalogScreen(),
      cartMode ? const CartScreen() : const ContactScreen(),
      const CashbackScreen(),
      const ProfileScreen(),
    ];
    final items = [
      (Icons.home_outlined, Icons.home_rounded, 'tab_home'),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, 'tab_catalog'),
      cartMode
          ? (Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'tab_cart')
          : (Icons.call_outlined, Icons.call_rounded, 'tab_order'),
      (Icons.toll_outlined, Icons.toll_rounded, 'tab_cashback'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'tab_profile'),
    ];
    return Scaffold(
      body: IndexedStack(index: state.tab, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: C.white,
          border: Border(top: BorderSide(color: C.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: InkResponse(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        state.setTab(i);
                      },
                      radius: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Badge(
                            isLabelVisible: cartMode && i == 2 && state.cartCount > 0,
                            backgroundColor: C.red,
                            label: Text(
                              '${state.cartCount}',
                              style: tsx(10, w: FontWeight.w900, c: C.white),
                            ),
                            child: Icon(
                              state.tab == i ? items[i].$2 : items[i].$1,
                              size: 26,
                              color: state.tab == i ? C.red : C.text3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            context.t(items[i].$3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tsx(
                              11.5,
                              w: state.tab == i ? FontWeight.w900 : FontWeight.w700,
                              c: state.tab == i ? C.red : C.text3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Katta ekranlarda (veb) ilovani o'rtadagi telefon-ramkada ko'rsatadi.
/// Telefon va tor oynalarda hech narsa o'zgarmaydi.
class _WebPhoneFrame extends StatelessWidget {
  final Widget child;
  const _WebPhoneFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth <= 620) return child;
        final mq = MediaQuery.of(context);
        final h = c.maxHeight - 48 < 920 ? c.maxHeight - 48 : 920.0;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF6F3F0), Color(0xFFEDE6E0)],
            ),
          ),
          child: Center(
            child: Container(
              width: 430,
              height: h,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0x14000000)),
                boxShadow: const [
                  BoxShadow(color: Color(0x1F000000), blurRadius: 48, offset: Offset(0, 20)),
                ],
              ),
              child: MediaQuery(
                data: mq.copyWith(size: Size(430, h), padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
