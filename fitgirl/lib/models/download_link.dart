/// Represents a download link extracted from an article page
/// Maps to DownloadLink model from Python backend
class DownloadLink {
  final String text;
  final String url;

  DownloadLink({
    required this.text,
    required this.url,
  });

  /// Create DownloadLink from JSON response
  factory DownloadLink.fromJson(Map<String, dynamic> json) {
    return DownloadLink(
      text: json['text'] as String,
      url: json['url'] as String,
    );
  }

  /// Convert to JSON (for potential caching or storage)
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'url': url,
    };
  }
}
