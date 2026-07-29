import 'package:PiliPlus/models_new/space/space_shop/below_label.dart';
import 'package:PiliPlus/models_new/space/space_shop/benefit_info.dart';
import 'package:PiliPlus/models_new/space/space_shop/cover.dart';
import 'package:PiliPlus/models_new/space/space_shop/net_price.dart';

class SpaceShopItem {
  Cover? cover;
  String? title;
  String? cardUrl;
  List<BelowLabel>? belowLabels;
  NetPrice? netPrice;
  List<BenefitInfo>? benefitInfos;
  String? itemSourceName;

  SpaceShopItem({
    this.cover,
    this.title,
    this.cardUrl,
    this.belowLabels,
    this.netPrice,
    this.benefitInfos,
    this.itemSourceName,
  });

  factory SpaceShopItem.fromJson(Map<String, dynamic> json) => SpaceShopItem(
    cover: json['cover'] == null
        ? null
        : Cover.fromJson(json['cover'] as Map<String, dynamic>),
    title: json['title'] as String?,
    cardUrl: json['cardUrl'] as String?,
    belowLabels: (json['belowLabels'] as List<dynamic>?)
        ?.map((e) => BelowLabel.fromJson(e as Map<String, dynamic>))
        .toList(),
    netPrice: json['netPrice'] == null
        ? null
        : NetPrice.fromJson(json['netPrice'] as Map<String, dynamic>),
    benefitInfos: (json['benefitInfos'] as List<dynamic>?)
        ?.map((e) => BenefitInfo.fromJson(e as Map<String, dynamic>))
        .toList(),
    itemSourceName: json['itemSourceName'] as String?,
  );
}
