import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/providers.dart';
import 'app/routes.dart';
import 'app/theme.dart';
import 'data/pack/bundled_pack_installer.dart';
import 'data/prefs/recent_selection_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // F-BUG-01: コールド起動時は前回セッションの直近選択を引き継がない。
  await RecentSelectionStore(prefs).clear();
  try {
    final supportDir = await getApplicationSupportDirectory();
    await BundledPackInstaller.ensureInstalled(
      Directory(p.join(supportDir.path, 'packs')),
    );
  } catch (_) {
    // path_provider 非対応環境（一部テスト）ではスキップ
  }
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const OfflineCenterApp(),
    ),
  );
}

/// アプリのルートウィジェット。
///
/// 初回は S-06（免責・権限）、完了後は S-01 ホーム (F-11)。
class OfflineCenterApp extends ConsumerWidget {
  const OfflineCenterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingCompleteProvider);

    if (onboarding.isLoading) {
      return MaterialApp(
        key: const ValueKey('app-boot'),
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final done = onboarding.valueOrNull ?? false;
    return MaterialApp(
      // loading 時の home 付き MaterialApp と State を共有しない
      key: ValueKey(done ? 'app-home' : 'app-onboarding'),
      title: 'オフライン災害対応センター',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // §15.4: 端末の設定に追従 (日出没ベースの自動切替は S-05 / #12 で拡張)。
      themeMode: ThemeMode.system,
      initialRoute: done ? AppRoutes.home : AppRoutes.onboarding,
      onGenerateRoute: onGenerateAppRoute,
    );
  }
}
