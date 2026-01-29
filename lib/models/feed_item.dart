class FeedItem {
  final String? title;
  final String? description;
  final String? link;
  final String? imageUrl;
  final String? content; // Full content for Reader Mode
  final DateTime? pubDate;

  FeedItem({
    this.title,
    this.description,
    this.link,
    this.imageUrl,
    this.content,
    this.pubDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'link': link,
      'imageUrl': imageUrl,
      'content': content,
      'pubDate': pubDate?.toIso8601String(),
    };
  }

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      title: json['title'],
      description: json['description'],
      link: json['link'],
      imageUrl: json['imageUrl'],
      content: json['content'],
      pubDate: json['pubDate'] != null ? DateTime.parse(json['pubDate']) : null,
    );
  }

  @override
  String toString() {
    return 'FeedItem(title: $title, pubDate: $pubDate)';
  }
}
