import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/situation_slots.dart';
import '../assistant/assistant_screen.dart';
import '../home/home_screen.dart';

/// アプリシェル（ホーム / アシスタント の2タブフッター）。
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.onSelect});

  final void Function(SituationSlots slots)? onSelect;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onSelect: widget.onSelect ?? _defaultOnSelect(context)),
          const AssistantScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: '災害対応アシスタント',
          ),
        ],
      ),
    );
  }

  void Function(SituationSlots slots) _defaultOnSelect(BuildContext context) {
    return (slots) {
      if (slots.disasterType == DisasterType.unknown &&
          !slots.needsDisasterTypeConfirmation) {
        Navigator.of(context).pushNamed(AppRoutes.guide);
      } else {
        Navigator.of(context).pushNamed(AppRoutes.result, arguments: slots);
      }
    };
  }
}
