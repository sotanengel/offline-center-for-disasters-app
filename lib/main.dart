import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: OfflineCenterApp()));
}

/// アプリのルートウィジェット。
/// 画面実装は PR-6 以降で `presentation/` 配下に追加される。
class OfflineCenterApp extends StatelessWidget {
  const OfflineCenterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'オフライン災害対応センター',
      theme: ThemeData(useMaterial3: true),
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('オフライン災害対応センター')),
      body: const Center(child: Text('準備中')),
    );
  }
}
