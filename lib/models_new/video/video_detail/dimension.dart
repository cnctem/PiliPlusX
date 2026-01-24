class Dimension {
  int? width;
  int? height;

  Dimension({this.width, this.height});

  factory Dimension.fromJson(Map<String, dynamic> json) => Dimension(
    width: json['width'] as int?,
    height: json['height'] as int?,
  );
}
