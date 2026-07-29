import 'package:PiliPlus/models_new/member_card_info/card.dart';

class MemberCardInfoData {
  Card? card;
  int? archiveCount;
  int? follower;

  MemberCardInfoData({
    this.card,
    this.archiveCount,
    this.follower,
  });

  factory MemberCardInfoData.fromJson(Map<String, dynamic> json) =>
      MemberCardInfoData(
        card: json['card'] == null
            ? null
            : Card.fromJson(json['card'] as Map<String, dynamic>),
        archiveCount: json['archive_count'] as int?,
        follower: json['follower'] as int?,
      );
}
