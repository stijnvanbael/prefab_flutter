import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Item', path: 'items')
class Item {
  final int id;
  @Field(on: {Place.detail, Place.form})
  final String secret;
  @Field(on: {Place.item, Place.form})
  final String name;
  @Field(on: {Place.item, Place.detail, Place.form})
  final String? note;
  final String everywhere;
  Item({required this.id, required this.secret, required this.name, this.note, required this.everywhere});
  factory Item.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
