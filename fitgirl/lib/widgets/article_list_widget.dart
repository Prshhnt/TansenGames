import 'package:flutter/material.dart';
import '../models/article_link.dart';

/// Displays a scrollable list of search results (article links)
/// Uses card-based design for clean presentation
class ArticleListWidget extends StatelessWidget {
  final List<ArticleLink> articles;
  final Function(ArticleLink) onArticleSelected;

  const ArticleListWidget({
    super.key,
    required this.articles,
    required this.onArticleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with result count
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'Found ${articles.length} result${articles.length != 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),

        // Scrollable list with smooth scrolling
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: true,
              physics: const BouncingScrollPhysics(),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final article = articles[index];

                return _ArticleCard(
                  article: article,
                  onTap: () => onArticleSelected(article),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual article card with hover effect
class _ArticleCard extends StatefulWidget {
  final ArticleLink article;
  final VoidCallback onTap;

  const _ArticleCard({required this.article, required this.onTap});

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Card(
          elevation: _isHovered ? 4 : 2,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.videogame_asset,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Title
                  Expanded(
                    child: Text(
                      widget.article.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
