class BelowLabel {
  String? title;

  BelowLabel({
    this.title,
  });

  factory BelowLabel.fromJson(Map<String, dynamic> json) => BelowLabel(
    title: json['title'] as String?,
  );
}
