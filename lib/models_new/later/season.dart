class Season {
  String? title;

  Season({
    this.title,
  });

  factory Season.fromJson(Map<String, dynamic> json) => Season(
    title: json['title'] as String?,
  );
}
