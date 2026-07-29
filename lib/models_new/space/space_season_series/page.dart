class SpaceSsPage {
  int? total;

  SpaceSsPage({
    this.total,
  });

  factory SpaceSsPage.fromJson(Map<String, dynamic> json) => SpaceSsPage(
    total: json["total"],
  );
}
