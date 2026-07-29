import 'package:PiliPlus/models_new/space/space/order.dart';
import 'package:PiliPlus/models_new/space/space_archive/item.dart';

class Archive {
  List<Order>? order;
  int? count;
  List<SpaceArchiveItem>? item;

  Archive({this.order, this.count, this.item});

  factory Archive.fromJson(Map<String, dynamic> json) => Archive(
    order: (json['order'] as List<dynamic>?)
        ?.map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList(),
    count: json['count'] as int?,
    item: (json['item'] as List<dynamic>?)
        ?.map((e) => SpaceArchiveItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
