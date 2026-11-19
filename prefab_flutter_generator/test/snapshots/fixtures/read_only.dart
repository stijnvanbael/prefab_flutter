import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Delta', path: 'deltas')
class Delta {
  final int? id;
  @Field()
  final String name;
  Delta({this.id, required this.name});
  factory Delta.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
