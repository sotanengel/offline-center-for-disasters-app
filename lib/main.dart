import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/providers.dart';
import 'app/routes.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const OfflineCenterApp(),
    ),
  );
}

/// アプリのルートウィジェット。
class OfflineCenterApp extends StatelessWidget {
  const OfflineCenterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'オフライン災害対応センター',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // §15.4: 端末の設定に追従 (日出没ベースの自動切替は S-05 / #12 で拡張)。
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.home,
      onGenerateRoute: onGenerateAppRoute,
    );
  }
}
