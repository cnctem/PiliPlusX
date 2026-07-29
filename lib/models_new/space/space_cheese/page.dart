class SpaceCheesePage {
  bool? next;

  SpaceCheesePage({this.next});

  factory SpaceCheesePage.fromJson(Map<String, dynamic> json) =>
      SpaceCheesePage(
        next: json['next'] as bool?,
      );
}
