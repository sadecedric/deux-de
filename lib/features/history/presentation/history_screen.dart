import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/services/game_history_controller.dart';
import '../../game/models/bet_choice.dart';
import '../models/history_entry.dart';
import '../widgets/history_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final GameHistoryController _history = GameHistoryController.instance;
  BetChoice? _filter;

  List<HistoryEntry> get _filteredEntries => _filter == null
      ? _history.entries
      : _history.entries.where((e) => e.result == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Résultats des lancers')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _history,
          builder: (context, _) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spaceM,
                  vertical: AppDimens.spaceS,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Toutes',
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      for (final choice in BetChoice.values)
                        _FilterChip(
                          label: choice.label,
                          selected: _filter == choice,
                          onTap: () => setState(() => _filter = choice),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _filteredEntries.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun lancer pour le moment',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.spaceM,
                        ),
                        itemCount: _filteredEntries.length,
                        itemBuilder: (context, index) =>
                            HistoryCard(entry: _filteredEntries[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.spaceS),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.gold
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.background : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
