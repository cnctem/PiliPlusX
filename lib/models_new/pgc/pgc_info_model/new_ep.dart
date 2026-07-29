class NewEp {
  String? desc;
  String? title;

  NewEp({this.desc, this.title});

  factory NewEp.fromJson(Map<String, dynamic> json) => NewEp(
    desc: json['desc'] as String?,
    title: json['title'] as String?,
  );
}
