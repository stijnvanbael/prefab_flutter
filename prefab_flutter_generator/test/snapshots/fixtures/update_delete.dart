import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Gamma', path: 'gammas')
@Update()
@Delete()
class Gamma {
  final int? id;
  @Field()
  final String name;
  Gamma({this.id, required this.name});
  factory Gamma.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
