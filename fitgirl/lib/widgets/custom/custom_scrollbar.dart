import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Themed scrollbar wrapper for lists and scroll views.
class CustomScrollbar extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final bool thumbAlwaysVisible;

  const CustomScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.thumbAlwaysVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: RawScrollbar(
        controller: controller,
        thumbVisibility: thumbAlwaysVisible,
        thickness: 8,
        radius: const Radius.circular(12),
        thumbColor: AppTheme.primary.withOpacity(0.7),
        trackColor: AppTheme.surfaceDark,
        trackBorderColor: AppTheme.borderColor,
        child: child,
      ),
    );
  }
}
