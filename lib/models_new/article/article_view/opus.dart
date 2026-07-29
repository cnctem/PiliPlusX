import 'package:PiliPlus/models/dynamics/article_content_model.dart';

class ArticleOpus {
  List<ArticleContentModel>? content;

  ArticleOpus.fromJson(Map<String, dynamic> json) {
    if (json['content']?['paragraphs'] case List list) {
      content = list.map((i) => ArticleContentModel.fromJson(i)).toList();
    }
  }
}
