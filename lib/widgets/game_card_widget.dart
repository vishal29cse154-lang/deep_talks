import 'package:flutter/material.dart';
import '../models/game_card_model.dart';
import '../theme/app_theme.dart';

class GameCardWidget extends StatelessWidget {
  final GameCardModel card;

  const GameCardWidget({super.key, required this.card});

  Color _categoryColor() {
    switch (card.category) {
      case GameCategory.warmUp:
        return const Color(0xFF4CAF50);
      case GameCategory.deepSecrets:
        return AppTheme.purple;
      case GameCategory.intimate:
        return AppTheme.accent;
    }
  }

  String _categoryLabel() {
    switch (card.category) {
      case GameCategory.warmUp:
        return '🔥 Warm Up';
      case GameCategory.deepSecrets:
        return '🤫 Deep Secrets';
      case GameCategory.intimate:
        return '💋 18+ Intimate';
    }
  }

  IconData _typeIcon() {
    return card.type == CardType.truth ? Icons.lightbulb : Icons.bolt;
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.25), AppTheme.cardDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _categoryLabel(),
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Type icon
              Icon(_typeIcon(), color: color, size: 42),

              const SizedBox(height: 12),

              // Type label
              Text(
                card.type == CardType.truth ? 'TRUTH' : 'DARE',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),

              const SizedBox(height: 24),

              // Card text
              Text(
                card.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
