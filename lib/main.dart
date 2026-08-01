import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/providers.dart';
import 'domain/entities/enums.dart';
import 'ui/home/home_screen.dart';

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
      theme: ThemeData(useMaterial3: true),
      home: HomeScreen(onSelect: _onDisasterSelected),
    );
  }

  /// 災害種別確定時の遷移。結果サマリ画面は PR-7 で接続する。
  static void _onDisasterSelected(DisasterType type) {
    // 直近選択への保存は HomeScreen 側で実施済み。
    // TODO(PR-7): 結果サマリ画面へ遷移する。
  }
}
