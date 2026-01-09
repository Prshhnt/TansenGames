/// Represents a search result article from FitGirl Repacks
/// Maps to ArticleLink model from Python backend
class ArticleLink {
  final String title;
  final String url;
  final String? posterUrl;

  ArticleLink({
    required this.title,
    required this.url,
    this.posterUrl,
  });

  /// Create ArticleLink from JSON response
  factory ArticleLink.fromJson(Map<String, dynamic> json) {
    return ArticleLink(
      title: json['title'] as String,
      url: json['url'] as String,
      posterUrl: json['poster_url'] as String?,
    );
  }

  /// Convert to JSON (for potential caching or storage)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'poster_url': posterUrl,
    };
  }
}
