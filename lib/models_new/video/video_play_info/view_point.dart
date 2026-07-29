class ViewPoint {
  int? type;
  int? from;
  int? to;
  String? content;
  String? imgUrl;

  ViewPoint({
    this.type,
    this.from,
    this.to,
    this.content,
    this.imgUrl,
  });

  factory ViewPoint.fromJson(Map<String, dynamic> json) => ViewPoint(
    type: json["type"],
    from: json["from"],
    to: json["to"],
    content: json["content"],
    imgUrl: json["imgUrl"],
  );
}
