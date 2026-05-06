import '../utils/json_utils.dart';

class Notice {
  final int id;
  final String title;
  final String content;
  final String? imgUrl;
  final DateTime createdAt;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    this.imgUrl,
    required this.createdAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: JsonUtils.asInt(json['id']),
      title: JsonUtils.asString(json['title']),
      content: JsonUtils.asString(json['content']),
      imgUrl: json['img_url'] is String ? json['img_url'] as String : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        JsonUtils.asInt(json['created_at']) * 1000,
      ),
    );
  }
}
