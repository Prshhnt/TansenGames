/// Represents detailed game metadata from the backend
class GameMetadata {
  final String url;
  final String title;
  final String fullTitle;
  final String updateNumber;
  final String posterUrl;
  final List<String> genres;
  final String companies;
  final String languages;
  final String requirements;
  final String originalSize;
  final String repackSize;
  final bool selectiveDownload;
  final List<String> repackFeatures;
  final String publishedDate;
  final String modifiedDate;
  final String description;

  const GameMetadata({
    required this.url,
    required this.title,
    required this.fullTitle,
    required this.updateNumber,
    required this.posterUrl,
    required this.genres,
    required this.companies,
    required this.languages,
    required this.requirements,
    required this.originalSize,
    required this.repackSize,
    required this.selectiveDownload,
    required this.repackFeatures,
    required this.publishedDate,
    required this.modifiedDate,
    required this.description,
  });

  factory GameMetadata.fromJson(Map<String, dynamic> json) {
    return GameMetadata(
      url: json['url'] as String,
      title: json['title'] as String? ?? '',
      fullTitle: json['full_title'] as String? ?? '',
      updateNumber: json['update_number'] as String? ?? '',
      posterUrl: json['poster_url'] as String? ?? '',
      genres: (json['genres'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      companies: json['companies'] as String? ?? '',
      languages: json['languages'] as String? ?? '',
      requirements: json['requirements'] as String? ?? '',
      originalSize: json['original_size'] as String? ?? '',
      repackSize: json['repack_size'] as String? ?? '',
      selectiveDownload: json['selective_download'] as bool? ?? false,
      repackFeatures:
          (json['repack_features'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      publishedDate: json['published_date'] as String? ?? '',
      modifiedDate: json['modified_date'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
      'full_title': fullTitle,
      'update_number': updateNumber,
      'poster_url': posterUrl,
      'genres': genres,
      'companies': companies,
      'languages': languages,
      'requirements': requirements,
      'original_size': originalSize,
      'repack_size': repackSize,
      'selective_download': selectiveDownload,
      'repack_features': repackFeatures,
      'published_date': publishedDate,
      'modified_date': modifiedDate,
      'description': description,
    };
  }
}
