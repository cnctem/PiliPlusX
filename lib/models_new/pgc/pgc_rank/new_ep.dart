class NewEp {
  String? indexShow;

  NewEp({this.indexShow});

  factory NewEp.fromJson(Map<String, dynamic> json) => NewEp(
    indexShow: json['index_show'] as String?,
  );
}
