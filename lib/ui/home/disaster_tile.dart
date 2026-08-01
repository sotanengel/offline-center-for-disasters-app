import 'package:flutter/material.dart';

/// 災害種別タイル（§3.2: 高さ ≥88dp、絵文字アイコン + 文字。色のみに依存しない）。
class DisasterTile extends StatelessWidget {
  const DisasterTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  /// §3.4-a: スコア ≥ 70 または揺れ検知による強調（枠線・サイズ拡大）。
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: emphasized
            ? scheme.errorContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: emphasized ? 3 : 1,
                color: emphasized ? scheme.error : scheme.outlineVariant,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: TextStyle(fontSize: emphasized ? 34 : 28)),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: emphasized
                        ? FontWeight.bold
                        : FontWeight.normal,
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
