import 'package:flutter/material.dart';

/// Search bar widget with integrated search button
/// Desktop-optimized with larger sizing and clear visual feedback
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool isLoading;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      constraints: const BoxConstraints(maxWidth: 700),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Search input field
          Flexible(
            child: TextField(
              controller: controller,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Search for games',
                hintText: 'e.g., Resident Evil, GTA V, Cyberpunk',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => onSearch(),
              textInputAction: TextInputAction.search,
            ),
          ),

          const SizedBox(width: 16),

          // Search button
          FilledButton.icon(
            onPressed: isLoading ? null : onSearch,
            style: FilledButton.styleFrom(minimumSize: const Size(140, 56)),
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(isLoading ? 'Searching...' : 'Search'),
          ),
        ],
      ),
    );
  }
}
