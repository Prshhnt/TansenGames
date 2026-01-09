import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Status badge component for showing download/game status
/// Features: Color-coded badges, icons, hover effects
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;
  final bool showIcon;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.info,
    this.icon,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              icon ?? _getDefaultIcon(type),
              size: 14,
              color: colors.textColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textColor,
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      ),
    );
  }

  _BadgeColors _getColors(StatusBadgeType type) {
    switch (type) {
      case StatusBadgeType.success:
        return _BadgeColors(
          backgroundColor: AppTheme.statusOnline.withOpacity(0.15),
          borderColor: AppTheme.statusOnline.withOpacity(0.3),
          textColor: AppTheme.statusOnline,
        );
      case StatusBadgeType.warning:
        return _BadgeColors(
          backgroundColor: AppTheme.statusWarning.withOpacity(0.15),
          borderColor: AppTheme.statusWarning.withOpacity(0.3),
          textColor: AppTheme.statusWarning,
        );
      case StatusBadgeType.error:
        return _BadgeColors(
          backgroundColor: AppTheme.statusError.withOpacity(0.15),
          borderColor: AppTheme.statusError.withOpacity(0.3),
          textColor: AppTheme.statusError,
        );
      case StatusBadgeType.info:
        return _BadgeColors(
          backgroundColor: AppTheme.primary.withOpacity(0.15),
          borderColor: AppTheme.primary.withOpacity(0.3),
          textColor: AppTheme.primary,
        );
      case StatusBadgeType.neutral:
        return _BadgeColors(
          backgroundColor: AppTheme.slate700,
          borderColor: AppTheme.slate600,
          textColor: AppTheme.slate300,
        );
    }
  }

  IconData _getDefaultIcon(StatusBadgeType type) {
    switch (type) {
      case StatusBadgeType.success:
        return Icons.check_circle;
      case StatusBadgeType.warning:
        return Icons.warning;
      case StatusBadgeType.error:
        return Icons.error;
      case StatusBadgeType.info:
        return Icons.info;
      case StatusBadgeType.neutral:
        return Icons.circle;
    }
  }
}

enum StatusBadgeType {
  success,
  warning,
  error,
  info,
  neutral,
}

class _BadgeColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  _BadgeColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}
