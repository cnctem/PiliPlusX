class Badge {
  String? text;

  Badge({
    this.text,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
    text: json['text'] as String?,
  );
}
