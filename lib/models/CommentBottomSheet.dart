// First, let's create the Comment model
class Comment {
  final int id;
  final int user;
  final String name;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profilePicture;
  final int replyCount;
  final List<Reply> replies;

  Comment({
    required this.id,
    required this.user,
    required this.name,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.profilePicture,
    required this.replyCount,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      user: json['user'],
      name: json['name'],
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      profilePicture: json['profile_picture'],
      replyCount: json['reply_count'],
      replies: (json['replies'] as List?)
          ?.map((reply) => Reply.fromJson(reply))
          .toList() ?? [],
    );
  }
}

class Reply {
  final int id;
  final int user;
  final String name;
  final String text;
  final DateTime createdAt;
  final String? profilePicture;

  Reply({
    required this.id,
    required this.user,
    required this.name,
    required this.text,
    required this.createdAt,
    this.profilePicture,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['id'],
      user: json['user'],
      name: json['name'],
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
      profilePicture: json['profile_picture'],
    );
  }
}

