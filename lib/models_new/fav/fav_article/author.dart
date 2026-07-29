class Author {
  String? name;

  Author({this.name});

  factory Author.fromJson(Map<String, dynamic> json) => Author(
    name: json['name'] as String?,
  );
}
