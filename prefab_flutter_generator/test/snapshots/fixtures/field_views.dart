import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Item', path: 'items')
class Item {
  final int id;
  @Field(views: {'detail'})
  final String secret;
  @Field(views: {'list'})
  final String name;
  @Field(views: {'list', 'detail'})
  final String? note;
  final String everywhere;
  Item({required this.id, required this.secret, required this.name, this.note, required this.everywhere});
  factory Item.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
