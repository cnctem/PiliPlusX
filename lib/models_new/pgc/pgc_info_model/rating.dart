class Rating {
  double? score;

  Rating({this.score});

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
    score: (json['score'] as num?)?.toDouble(),
  );
}
