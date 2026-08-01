import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';

/// S-06 初回セットアップ（§17 免責・権限・パック提案）。
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _agreed = false;
  bool _busy = false;

  static const _disclaimer = '''
自治体・気象庁等の公式指示が最優先です。
本アプリは最新の被害・通行止めを反映しない場合があります。
経路と避難先の安全は保証されません。
''';

  Future<void> _continue() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // F-11 / §16.4: 位置情報（使用中のみ）を要求。拒否しても進める (§3.8)。
      final location = ref.read(locationServiceProvider);
      final perm = await location.checkPermission();
      if (perm == LocationPermission.denied) {
        await location.requestPermission();
      }
      await ref.read(onboardingCompleteProvider.notifier).setComplete(true);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('初回セットアップ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '免責事項',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _disclaimer,
              style: const TextStyle(fontSize: 18, height: 1.4),
            ),
            CheckboxListTile(
              value: _agreed,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _agreed = v ?? false),
              title: const Text('上記に同意する'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _agreed && !_busy ? _continue : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('続ける', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
