class LevelInfo {
  int? currentLevel;
  int? identity;

  LevelInfo({
    this.currentLevel,
    this.identity,
  });

  factory LevelInfo.fromJson(Map<String, dynamic> json) => LevelInfo(
    currentLevel: json['current_level'] as int?,
    identity: json['identity'] as int?,
  );
}
