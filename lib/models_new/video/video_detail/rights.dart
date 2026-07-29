class Rights {
  int? isSteinGate;

  Rights({
    this.isSteinGate,
  });

  factory Rights.fromJson(Map<String, dynamic> json) => Rights(
    isSteinGate: json['is_stein_gate'] as int?,
  );
}
