import 'package:prefab_flutter/prefab_flutter.dart';

enum Genre { novel, poetry }

@Entity(title: 'Novel', path: 'novels', paged: false)
class Novel {
  final int id;
  @Field(searchable: true, filterable: true)
  final String title;
  @Field(filterable: true)
  final Genre? genre;
  @Field(filterable: true)
  final bool published;
  @Field(filterable: true)
  final DateTime? releasedOn;
  Novel({required this.id, required this.title, this.genre, required this.published, this.releasedOn});
  factory Novel.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
