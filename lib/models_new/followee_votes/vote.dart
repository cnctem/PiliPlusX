class FolloweeVote {
  int uid;
  String name;
  String face;
  List<int> votes;
  int ctime;

  FolloweeVote({
    required this.uid,
    required this.name,
    required this.face,
    required this.votes,
    required this.ctime,
  });

  factory FolloweeVote.fromJson(Map<String, dynamic> json) => FolloweeVote(
    uid: json['uid'],
    name: json['name'],
    face: json['face'],
    votes: List<int>.from(json['votes']),
    ctime: json['ctime'],
  );
}
