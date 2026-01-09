import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Breadcrumb navigation component for showing navigation path
/// Features: Hover effects, clickable segments, separator styling
class BreadcrumbNavigation extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const BreadcrumbNavigation({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (int i = 0; i < items.length; i++) {
      children.add(
        _BreadcrumbSegment(
          item: items[i],
          isLast: i == items.length - 1,
        ),
      );

      if (i < items.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: AppTheme.slate500,
            ),
          ),
        );
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class _BreadcrumbSegment extends StatefulWidget {
  final BreadcrumbItem item;
  final bool isLast;

  const _BreadcrumbSegment({
    required this.item,
    required this.isLast,
  });

  @override
  State<_BreadcrumbSegment> createState() => _BreadcrumbSegmentState();
}

class _BreadcrumbSegmentState extends State<_BreadcrumbSegment> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isClickable = widget.item.onTap != null && !widget.isLast;

    return MouseRegion(
      onEnter: isClickable ? (_) => setState(() => _isHovered = true) : null,
      onExit: isClickable ? (_) => setState(() => _isHovered = false) : null,
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isClickable ? widget.item.onTap : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.item.icon != null) ...[
              Icon(
                widget.item.icon,
                size: 16,
                color: widget.isLast
                    ? AppTheme.slate300
                    : (_isHovered ? AppTheme.primary : AppTheme.slate400),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              widget.item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: widget.isLast ? FontWeight.w600 : FontWeight.w500,
                color: widget.isLast
                    ? AppTheme.slate300
                    : (_isHovered ? AppTheme.primary : AppTheme.slate400),
                fontFamily: 'NotoSans',
                decoration: _isHovered && isClickable
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data model for a breadcrumb item
class BreadcrumbItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const BreadcrumbItem({
    required this.label,
    this.icon,
    this.onTap,
  });
}
