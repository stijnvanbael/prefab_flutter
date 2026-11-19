import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Item', path: 'items')
class Item {
  final int id;
  final String name;
  Item({required this.id, required this.name});
  factory Item.fromJson(Map<String, dynamic> json) => Item(id: 1, name: '');
  Map<String, dynamic> toJson() => {};
}
