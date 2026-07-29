class PopularSeriesListItem {
  int? number;
  String? name;

  PopularSeriesListItem({this.number, this.name});

  factory PopularSeriesListItem.fromJson(Map<String, dynamic> json) =>
      PopularSeriesListItem(
        number: json['number'] as int?,
        name: json['name'] as String?,
      );
}
