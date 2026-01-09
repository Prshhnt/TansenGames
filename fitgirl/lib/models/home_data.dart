import 'article_link.dart';

class HomeItem {
  final String title;
  final String url;
  final String? image;
  final String? version;
  final String? publishedDate;
  final String? repackSize;

  const HomeItem({
    required this.title,
    required this.url,
    this.image,
    this.version,
    this.publishedDate,
    this.repackSize,
  });

  factory HomeItem.fromJson(Map<String, dynamic> json) {
    return HomeItem(
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      image: (json['image'] as String?)?.trim().isEmpty == true
          ? null
          : json['image'] as String?,
      version: json['version']?.toString(),
      publishedDate: json['published_date']?.toString(),
      repackSize: json['repack_size']?.toString(),
    );
  }
}

class HomeData {
  final HomeItem? featured;
  final List<HomeItem> latest;
  final List<String> upcoming;
  final List<ArticleLink> popular;

  const HomeData({
    required this.featured,
    required this.latest,
    required this.upcoming,
    required this.popular,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final latestJson = (json['latest'] as List<dynamic>?) ?? const [];
    final upcomingJson = (json['upcoming'] as List<dynamic>?) ?? const [];
    final popularJson = (json['popular'] as List<dynamic>?) ?? const [];

    return HomeData(
      featured: json['featured'] != null
          ? HomeItem.fromJson(json['featured'] as Map<String, dynamic>)
          : null,
      latest: latestJson
          .map((e) => HomeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcoming: upcomingJson.map((e) => e.toString()).toList(),
      popular: popularJson
          .map((e) => ArticleLink.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
