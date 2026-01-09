import 'package:flutter/material.dart';
import '../../constants/hero_tags.dart';
import '../../theme/app_theme.dart';

/// Custom search bar matching HTML mockup design
/// Dark themed with rounded corners and embedded search button
class CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool isLoading;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.isLoading = false,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: searchBarHeroTag,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused ? AppTheme.primary : AppTheme.slate700,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Search Icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.search_rounded,
                  size: 24,
                  color: _isFocused ? AppTheme.primary : AppTheme.slate400,
                ),
              ),

              // Text Input
              Expanded(
                child: Focus(
                  onFocusChange: (focused) {
                    setState(() => _isFocused = focused);
                  },
                  child: TextField(
                    controller: widget.controller,
                    onSubmitted: (_) => widget.onSearch(),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontFamily: 'SpaceGrotesk',
                    ),
                    decoration: const InputDecoration(
                      hintText: "Search for repacks (e.g., 'Cyberpunk', 'Elden Ring')...",
                      hintStyle: TextStyle(
                        color: AppTheme.slate500,
                        fontSize: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),

              // Search Button
              Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: widget.isLoading ? AppTheme.slate600 : AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: widget.isLoading ? null : widget.onSearch,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Search',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
