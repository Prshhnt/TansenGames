import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Filter chips for sorting and filtering search results
class CustomFilterChips extends StatelessWidget {
  final String? selectedSort;
  final Function(String?) onSortChanged;
  final int resultCount;
  final double searchTime;

  const CustomFilterChips({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
    required this.resultCount,
    required this.searchTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Filter chips
        Wrap(
          spacing: 8,
          children: [
            _FilterChip(
              label: 'Sort by Date',
              isSelected: selectedSort == 'date',
              onTap: () => onSortChanged(selectedSort == 'date' ? null : 'date'),
              showIcon: true,
            ),
            _FilterChip(
              label: 'Size',
              isSelected: selectedSort == 'size',
              onTap: () => onSortChanged(selectedSort == 'size' ? null : 'size'),
            ),
            _FilterChip(
              label: 'Seeders',
              isSelected: selectedSort == 'seeders',
              onTap: () => onSortChanged(selectedSort == 'seeders' ? null : 'seeders'),
            ),
          ],
        ),
        
        // Results info
        Text(
          'Found $resultCount results in ${searchTime.toStringAsFixed(2)}s',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.slate500,
            fontFamily: 'NotoSans',
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showIcon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showIcon = false,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered != value) {
      setState(() => _isHovered = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Material(
        color: widget.isSelected 
          ? AppTheme.primary.withOpacity(0.1) 
          : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.isSelected 
                  ? AppTheme.primary.withOpacity(0.2)
                  : _isHovered 
                    ? AppTheme.slate600 
                    : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.isSelected ? AppTheme.primary : AppTheme.slate400,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                if (widget.showIcon) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: widget.isSelected ? AppTheme.primary : AppTheme.slate400,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
