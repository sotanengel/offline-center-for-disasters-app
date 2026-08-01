import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'guide_card.freezed.dart';

/// §11.2 監修済みガイドカード（KB 1 件）。
///
/// JSON スキーマは要件定義書 §11.2 に一致すること。
/// 生成 AI の出力はここに混ぜてはならない（MUST）。
@freezed
abstract class GuideCard with _$GuideCard {
  const factory GuideCard({
    required String id,
    required String title,

    /// 対象災害種別（複数可）。
    @Default(<DisasterType>[]) List<DisasterType> disasterTypes,

    /// タグ（意図・状況キーワード）。
    @Default(<String>[]) List<String> tags,

    /// 表示順（小さいほど優先。§11.1 の一次スコアリング後の並び用）。
    @Default(0) int priority,

    /// マッチ条件（例: waterLevel: knee, mobility: wheelchair）。
    /// 実装依存の文字列 → 文字列マップ。空なら条件なし。
    @Default(<String, String>{}) Map<String, String> conditions,

    /// 手順本文（最大 5 ステップ推奨、§15.2）。
    @Default(<String>[]) List<String> steps,

    /// 注意書き（オプション）。表示時は視覚的に区別する。
    String? warning,

    /// §11 MUST: 出典（気象庁/内閣府/消防庁 等）。空文字禁止。
    required String source,

    /// 出典の更新日（YYYY-MM-DD 等）。
    String? sourceUpdated,
  }) = _GuideCard;
}
