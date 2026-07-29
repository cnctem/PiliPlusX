class Area {
  String? name;

  Area({this.name});

  factory Area.fromJson(Map<String, dynamic> json) => Area(
    name: json['name'] as String?,
  );
}
