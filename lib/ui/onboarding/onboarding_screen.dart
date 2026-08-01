import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// S-06 初回セットアップ（§17 免責・権限・パック提案）。
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _agreed = false;

  static const _disclaimer = '''
自治体・気象庁等の公式指示が最優先です。
本アプリは最新の被害・通行止めを反映しない場合があります。
経路と避難先の安全は保証されません。
''';

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
              onChanged: (v) => setState(() => _agreed = v ?? false),
              title: const Text('上記に同意する'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _agreed
                  ? () async {
                      await ref
                          .read(onboardingCompleteProvider.notifier)
                          .setComplete(true);
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    }
                  : null,
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
