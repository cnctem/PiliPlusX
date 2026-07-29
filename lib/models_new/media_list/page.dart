class Page {
  int? id;

  Page({
    this.id,
  });

  factory Page.fromJson(Map<String, dynamic> json) => Page(
    id: json["id"],
  );
}
