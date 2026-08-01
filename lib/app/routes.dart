import 'package:flutter/material.dart';

import '../domain/entities/enums.dart';
import '../ui/home/home_screen.dart';

/// アプリ全体のルート定数。
///
/// §15.1 MUST NOT: ボトムナビ / ドロワー / タブは追加しない。
/// ホーム → 結果は 1 タップで到達する（[onGenerateRoute] の /result 直行）。
class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const result = '/result';
  static const nav = '/nav';
  static const guide = '/guide';
  static const settings = '/settings';
  static const onboarding = '/onboarding';
}

/// [MaterialApp.onGenerateRoute] に渡すディスパッチャ。
///
/// 各画面が未実装 (PR-7/PR-8/PR-10) の間は「準備中」プレースホルダを返す。
Route<Object?>? onGenerateAppRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.home:
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => HomeScreen(
          onSelect: (type) => Navigator.of(
            context,
          ).pushNamed(AppRoutes.result, arguments: type),
        ),
      );
    case AppRoutes.result:
      final type = settings.arguments as DisasterType?;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => _PlaceholderScreen(
          routeName: '結果サマリ (S-02)',
          note: type == null ? null : '選択された災害種別: ${type.name}',
        ),
      );
    case AppRoutes.nav:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const _PlaceholderScreen(routeName: '経路案内 (S-03)'),
      );
    case AppRoutes.guide:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const _PlaceholderScreen(routeName: 'ガイド詳細 (S-04)'),
      );
    case AppRoutes.settings:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const _PlaceholderScreen(routeName: '設定 (S-05)'),
      );
    case AppRoutes.onboarding:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const _PlaceholderScreen(routeName: '初回セットアップ (S-06)'),
      );
    default:
      return null;
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.routeName, this.note});

  final String routeName;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(routeName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'この画面は準備中です',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (note != null) ...[
                const SizedBox(height: 8),
                Text(note!, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
