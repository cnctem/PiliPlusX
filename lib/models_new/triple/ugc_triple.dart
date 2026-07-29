class UgcTriple {
  bool? like;
  bool? coin;
  bool? fav;
  int? multiply;

  UgcTriple({
    this.like,
    this.coin,
    this.fav,
    this.multiply,
  });

  factory UgcTriple.fromJson(Map<String, dynamic> json) => UgcTriple(
    like: json["like"],
    coin: json["coin"],
    fav: json["fav"],
    multiply: json["multiply"],
  );
}
