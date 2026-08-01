import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/result/result.dart';
import '../../domain/entities/disaster_candidate.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/guide_card.dart';
import '../../domain/entities/situation_slots.dart';
import '../../domain/services/guidance_service.dart';
import 'guide_detail_screen.dart';

/// §3.6 縮退動作画面: 一般原則 + ハザードプライア上位3種チップ。
class GuideDegradeScreen extends ConsumerWidget {
  const GuideDegradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidates = ref.watch(disasterCandidatesProvider).value ?? const [];
    final top3 = candidates.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('今すべきこと（縮退モード）')),
      body: SafeArea(
        child: FutureBuilder<Result<List<GuideCard>, GuidanceServiceError>>(
          future: _loadGeneral(ref),
          builder: (context, snap) {
            final cards = switch (snap.data) {
              Ok(value: final v) => v,
              _ => const <GuideCard>[],
            };
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Material(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '災害種別が未確定のため、一般原則に基づくガイドを表示しています（§3.6 縮退モード）',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final c in cards)
                  ListTile(
                    title: Text(c.title, style: const TextStyle(fontSize: 20)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GuideDetailScreen(card: c),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  '災害種別を選んで再検索',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in top3)
                      _HazardChip(
                        candidate: c,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed('/result', arguments: c.type),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<Result<List<GuideCard>, GuidanceServiceError>> _loadGeneral(
    WidgetRef ref,
  ) async {
    final svc = ref.read(guidanceServiceProvider);
    const slots = SituationSlots(disasterType: DisasterType.unknown);
    final r = await svc.search(
      slots: slots,
      type: DisasterType.unknown,
      limit: 4,
    );
    return switch (r) {
      Ok(value: final v) => Ok(
        v.where((c) => c.tags.contains('principle')).toList(),
      ),
      Err() => Ok(const []),
    };
  }
}

class _HazardChip extends StatelessWidget {
  const _HazardChip({required this.candidate, required this.onTap});

  final DisasterCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: candidate.type.name,
      child: Material(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              candidate.type.name,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
