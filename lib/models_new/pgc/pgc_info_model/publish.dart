class Publish {
  String? pubTimeShow;

  Publish({
    this.pubTimeShow,
  });

  factory Publish.fromJson(Map<String, dynamic> json) => Publish(
    pubTimeShow: json['pub_time_show'] as String?,
  );
}
