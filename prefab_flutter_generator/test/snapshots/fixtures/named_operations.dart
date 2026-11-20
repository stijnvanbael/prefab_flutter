import 'package:prefab_flutter/prefab_flutter.dart';

class StartParameters {
  @Field(label: 'Connector', form: FormOptions(validators: [Validator.required]))
  final String connector;
  @Field(label: 'Limit (kWh)')
  final int? limit;
  const StartParameters({required this.connector, this.limit});
  Map<String, dynamic> toJson() => {'connector': connector, 'limit': limit};
}

@Entity(title: 'Charger', path: 'chargers')
@Update()
@Update(path: 'start', label: 'Start', icon: 'play_arrow', parameters: StartParameters)
@Update(
  path: 'stop',
  confirm: 'Stop charging?',
  on: {Place.detail, Place.item},
)
class Charger {
  final int? id;
  @Field()
  final String name;
  Charger({this.id, required this.name});
  factory Charger.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}

@Entity(title: 'Session', path: 'sessions')
@Update(path: 'mark-paid', on: {Place.item})
class Session {
  final int? id;
  @Parent(Charger)
  @Field()
  final int chargerId;
  @Field()
  final String name;
  Session({this.id, required this.chargerId, required this.name});
  factory Session.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
