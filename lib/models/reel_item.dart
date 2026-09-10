class ReelItem {
  final String id;
  final String title;
  final String author;
  final String authorUrl;
  final String thumbnailUrl;
  final String videoUrl;
  final String duration;
  final String? likes;
  final String? comments;
  final String originalUrl;
  final DateTime downloadedAt;
  final String? localFilePath;

  ReelItem({
    required this.id,
    required this.title,
    required this.author,
    required this.authorUrl,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.duration,
    this.likes,
    this.comments,
    required this.originalUrl,
    DateTime? downloadedAt,
    this.localFilePath,
  }) : downloadedAt = downloadedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'authorUrl': authorUrl,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'duration': duration,
      'likes': likes,
      'comments': comments,
      'originalUrl': originalUrl,
      'downloadedAt': downloadedAt.toIso8601String(),
      'localFilePath': localFilePath,
    };
  }

  factory ReelItem.fromJson(Map<String, dynamic> json) {
    return ReelItem(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Instagram Reel',
      author: json['author'] ?? 'Instagram Creator',
      authorUrl: json['authorUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      duration: json['duration'] ?? '0:15',
      likes: json['likes'],
      comments: json['comments'],
      originalUrl: json['originalUrl'] ?? '',
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.tryParse(json['downloadedAt']) ?? DateTime.now()
          : DateTime.now(),
      localFilePath: json['localFilePath'],
    );
  }

  ReelItem copyWith({String? localFilePath}) {
    return ReelItem(
      id: id,
      title: title,
      author: author,
      authorUrl: authorUrl,
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      duration: duration,
      likes: likes,
      comments: comments,
      originalUrl: originalUrl,
      downloadedAt: downloadedAt,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}
