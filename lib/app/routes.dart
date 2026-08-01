import 'package:flutter/material.dart';

import 'providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/guide_card.dart';
import '../../domain/entities/situation_slots.dart';
import '../ui/guide/guide_degrade_screen.dart';
import '../ui/guide/guide_detail_screen.dart';
import '../ui/home/home_screen.dart';
import '../ui/nav/nav_screen.dart';
import '../ui/onboarding/onboarding_screen.dart';
import '../ui/result/result_screen.dart' show NavArgs, ResultScreen;
import '../ui/settings/settings_screen.dart';

/// アプリ全体のルート定数。
class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const result = '/result';
  static const nav = '/nav';
  static const guide = '/guide';
  static const settings = '/settings';
  static const onboarding = '/onboarding';
}

Route<Object?>? onGenerateAppRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.home:
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => HomeScreen(
          onSelect: (slots) {
            if (slots.disasterType == DisasterType.unknown &&
                !slots.needsDisasterTypeConfirmation) {
              Navigator.of(context).pushNamed(AppRoutes.guide);
            } else {
              Navigator.of(
                context,
              ).pushNamed(AppRoutes.result, arguments: slots);
            }
          },
        ),
      );
    case AppRoutes.result:
      final slots =
          settings.arguments as SituationSlots? ??
          const SituationSlots(disasterType: DisasterType.unknown);
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => ResultScreen(slots: slots),
      );
    case AppRoutes.nav:
      final args = settings.arguments as NavArgs?;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => NavScreen(
          origin: args?.origin ?? kDefaultOrigin,
          route: args?.route,
          fallbackBearing: args?.fallbackBearing ?? false,
        ),
      );
    case AppRoutes.guide:
      final args = settings.arguments;
      if (args is GuideDetailArgs) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => GuideDetailScreen(
            card: args.card,
            aiSupplement: args.aiSupplement,
          ),
        );
      }
      final card = args as GuideCard?;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => card != null
            ? GuideDetailScreen(card: card)
            : const GuideDegradeScreen(),
      );
    case AppRoutes.settings:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const SettingsScreen(),
      );
    case AppRoutes.onboarding:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const OnboardingScreen(),
      );
    default:
      return null;
  }
}

/// ガイド詳細画面への引数（AI-4 補足文付き）。
class GuideDetailArgs {
  const GuideDetailArgs({required this.card, this.aiSupplement});
  final GuideCard card;
  final String? aiSupplement;
}
