class RejectPage {
  String? title;
  String? text;

  RejectPage({this.title, this.text});

  factory RejectPage.fromJson(Map<String, dynamic> json) => RejectPage(
    title: json['title'] as String?,
    text: json['text'] as String?,
  );
}
