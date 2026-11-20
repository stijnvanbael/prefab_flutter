import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Alpha', path: 'alphas')
@Update()
@Delete()
class Alpha {
  final int? id;
  @Field()
  final String name;
  @Field()
  final String? note;
  Alpha({this.id, required this.name, this.note});
  factory Alpha.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
