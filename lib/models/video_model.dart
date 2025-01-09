
class VideoModel {
  final int? id;
  final int? position;
  final String? tag;
  final String? videoUrl;
  final String thumbnail;
  final double duration;
  final String? createdAt;

  VideoModel({
    this.id,
    this.position,
    this.tag,
    this.videoUrl,
    required this.thumbnail,
    required this.duration,
    this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'],
      position: json['position'],
      tag: json['tag'],
      videoUrl: json['video_url'],
      thumbnail: json['thumbnail'] ?? '',
      duration: json['duration'] ?? 0,
      createdAt: json['created_at'],
    );
  }
}