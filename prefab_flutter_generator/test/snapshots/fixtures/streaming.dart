import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Device', path: 'devices')
@Delete()
@Streaming()
class Device {
  final int? id;
  @Field(searchable: true)
  final String name;
  Device({this.id, required this.name});
  factory Device.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}

@Entity(title: 'Site', path: 'sites')
class Site {
  final int id;
  @Field()
  final String name;
  Site({required this.id, required this.name});
  factory Site.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}

@Entity(title: 'Measurement', path: 'measurements', paged: false)
@Streaming()
class Measurement {
  final int? id;
  @Parent(Site)
  @Field(on: {})
  final int siteId;
  @Field()
  final double value;
  Measurement({this.id, required this.siteId, required this.value});
  factory Measurement.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
