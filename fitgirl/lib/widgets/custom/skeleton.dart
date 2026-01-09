import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Simple pulsing skeleton block used for loading states.
class SkeletonBlock extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock> {
  double _t = 0.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _t, end: _t == 0 ? 1 : 0),
      duration: const Duration(milliseconds: 900),
      onEnd: () => setState(() => _t = _t == 0 ? 1 : 0),
      builder: (context, value, _) {
        final base = AppTheme.surfaceDark;
        final highlight = AppTheme.surfaceHover;
        final color = Color.lerp(base, highlight, 0.35 + 0.3 * value)!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: widget.borderRadius,
            border: Border.all(color: AppTheme.borderColor),
          ),
        );
      },
    );
  }
}

/// Skeleton list used for game search results.
class GameListSkeletonList extends StatelessWidget {
  final int itemCount;

  const GameListSkeletonList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: const [
            SkeletonBlock(width: 80, height: 80),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: double.infinity, height: 18),
                  SizedBox(height: 10),
                  SkeletonBlock(width: 220, height: 12),
                ],
              ),
            ),
            SizedBox(width: 16),
            SkeletonBlock(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
          ],
        ),
      ),
    );
  }
}
