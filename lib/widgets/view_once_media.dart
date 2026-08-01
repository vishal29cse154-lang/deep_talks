import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ViewOnceMedia extends StatelessWidget {
  final bool isOpened;
  final VoidCallback? onTap;

  const ViewOnceMedia({super.key, required this.isOpened, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isOpened) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_off_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Expired Media',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Tap to View Once',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
