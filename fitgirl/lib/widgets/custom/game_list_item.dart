import 'package:flutter/material.dart';
import '../../models/article_link.dart';
import '../../theme/app_theme.dart';

/// Game list item with hover effects matching HTML mockup
class GameListItem extends StatefulWidget {
  final ArticleLink article;
  final VoidCallback onTap;

  const GameListItem({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  State<GameListItem> createState() => _GameListItemState();
}

class _GameListItemState extends State<GameListItem> {
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered 
              ? AppTheme.primary.withOpacity(0.5) 
              : AppTheme.slate800,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                // Hover Accent Line (left edge)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isHovered ? 4 : 0,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                ),
                
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Thumbnail placeholder (80x80)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.slate700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.videogame_asset_rounded,
                            size: 32,
                            color: AppTheme.slate500,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Title and metadata
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title with hover color change
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _isHovered 
                                    ? AppTheme.primary 
                                    : Colors.white,
                                  fontFamily: 'SpaceGrotesk',
                                ),
                                child: Text(
                                  widget.article.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // URL (truncated)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.link,
                                    size: 16,
                                    color: AppTheme.slate500,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.article.url,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.slate500,
                                        fontFamily: 'NotoSans',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Download button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF111A22),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isHovered 
                                ? AppTheme.primary 
                                : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.download_rounded,
                            color: _isHovered 
                              ? Colors.white 
                              : AppTheme.primary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
