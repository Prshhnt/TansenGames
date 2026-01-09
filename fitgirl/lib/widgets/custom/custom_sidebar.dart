import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Custom sidebar navigation matching HTML mockup
/// Replaces NavigationRail with custom dark design
class CustomSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const CustomSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: Color(0xFF111A22), // Slightly darker than surfaceDark
        border: Border(
          right: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header with logo
          _buildHeader(),
          
          // Navigation Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isActive: selectedIndex == 0,
                    onTap: () => onDestinationSelected(0),
                  ),
                  _NavItem(
                    icon: Icons.search_rounded,
                    label: 'Search',
                    isActive: selectedIndex == 1,
                    onTap: () => onDestinationSelected(1),
                  ),
                  _NavItem(
                    icon: Icons.history_rounded,
                    label: 'History',
                    isActive: selectedIndex == 2,
                    onTap: () => onDestinationSelected(2),
                  ),
                  _NavItem(
                    icon: Icons.star_rounded,
                    label: 'Popular',
                    isActive: selectedIndex == 3,
                    onTap: () => onDestinationSelected(3),
                  ),
                  _NavItem(
                    icon: Icons.download_rounded,
                    label: 'Downloads',
                    badge: null, // Can add download count badge later
                    isActive: selectedIndex == 4,
                    onTap: () => onDestinationSelected(4),
                  ),
                  _NavItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    badge: null,
                    isActive: selectedIndex == 5,
                    onTap: () => onDestinationSelected(5),
                  ),
                ],
              ),
            ),
          ),
          
          // Status Footer
          _buildStatusFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24).copyWith(bottom: 8),
      child: Row(
        children: [
          // Logo container with gradient
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'F',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Tansen Games',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.0,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              SizedBox(height: 4),
              Text(
                'v1.0.2',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.slate400,
                  fontFamily: 'Monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            // Pulsing green dot
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.statusOnline,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'All systems operational',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.slate300,
                fontFamily: 'NotoSans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual navigation item with hover effects
class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered != value) {
      setState(() => _isHovered = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isActive 
              ? AppTheme.primary.withOpacity(0.1)
              : _isHovered 
                ? AppTheme.surfaceHover
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8),
              splashColor: Colors.transparent,
              highlightColor: AppTheme.surfaceHover.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    AnimatedScale(
                      scale: _isHovered && !widget.isActive ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: widget.isActive 
                          ? AppTheme.primary 
                          : _isHovered 
                            ? Colors.white 
                            : AppTheme.slate400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: widget.isActive 
                            ? FontWeight.w700 
                            : FontWeight.w500,
                          color: widget.isActive 
                            ? AppTheme.primary 
                            : _isHovered 
                              ? Colors.white 
                              : AppTheme.slate400,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ),
                    if (widget.badge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.badge!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
