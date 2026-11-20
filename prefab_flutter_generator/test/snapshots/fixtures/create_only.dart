import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Beta', path: 'betas')
@Create()
class Beta {
  final int? id;
  @Field()
  final String name;
  Beta({this.id, required this.name});
  factory Beta.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
