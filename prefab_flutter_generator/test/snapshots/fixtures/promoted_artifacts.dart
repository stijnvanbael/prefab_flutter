import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Alpha', path: 'alphas')
@Create()
@Update()
@Delete()
class Alpha {
  final int? id;
  @Field()
  final String name;
  Alpha({this.id, required this.name});
  factory Alpha.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
