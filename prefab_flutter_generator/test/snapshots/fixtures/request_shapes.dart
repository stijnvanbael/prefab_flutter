import 'package:prefab_flutter/prefab_flutter.dart';

enum TicketState { open, closed }

@Entity(title: 'Ticket', path: 'tickets')
@Create()
@Update()
class Ticket {
  final int? id;

  @Field()
  final String title;

  /// Set when the ticket is created, never changed.
  @Field(form: FormOptions(on: {FormMode.create}))
  final String reporter;

  /// Written when the ticket is closed.
  @Field(form: FormOptions(on: {FormMode.update}))
  final String? resolution;

  /// Server-set: shown in the views, never in a form or a request.
  @Field(readOnly: true)
  final DateTime created;

  @Field(readOnly: true)
  final TicketState state;

  Ticket({
    this.id,
    required this.title,
    required this.reporter,
    this.resolution,
    required this.created,
    required this.state,
  });
  factory Ticket.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
