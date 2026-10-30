import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state.dart';

/// Pushes a screen on top of the tab shell.
Future<T?> push<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));

/// Returns to the tab shell and selects a tab.
void goTab(BuildContext context, int tab) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  context.read<AppState>().setTab(tab);
}
