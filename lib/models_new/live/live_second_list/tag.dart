class LiveSecondTag {
  String? name;
  String? sortType;

  LiveSecondTag({
    this.name,
    this.sortType,
  });

  factory LiveSecondTag.fromJson(Map json) => LiveSecondTag(
    name: json['name'],
    sortType: json['sort_type'],
  );
}
