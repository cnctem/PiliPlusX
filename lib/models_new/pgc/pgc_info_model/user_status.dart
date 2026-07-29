import 'package:PiliPlus/models_new/pgc/pgc_info_model/user_progress.dart';

class UserStatus {
  UserProgress? progress;
  int? favored;

  UserStatus({
    this.progress,
    this.favored,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) => UserStatus(
    progress: json['progress'] == null
        ? null
        : UserProgress.fromJson(json['progress']),
    favored: json['favored'] as int?,
  );
}
