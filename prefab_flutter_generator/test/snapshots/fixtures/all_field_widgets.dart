import 'package:prefab_flutter/prefab_flutter.dart';

enum Status { open, closed }

@View(title: 'Widget Demo', path: 'widget-demos')
@Create()
@Update()
class WidgetDemo {
  final int? id;
  @Field(form: FormOptions(widget: FieldWidget.auto))
  final String auto;
  @Field(form: FormOptions(widget: FieldWidget.multilineText))
  final String notes;
  @Field(form: FormOptions(widget: FieldWidget.password))
  final String secret;
  @Field(form: FormOptions(widget: FieldWidget.numberInput))
  final int quantity;
  @Field(form: FormOptions(widget: FieldWidget.datePicker))
  final DateTime day;
  @Field(form: FormOptions(widget: FieldWidget.timePicker))
  final String at;
  @Field(form: FormOptions(widget: FieldWidget.dateTimePicker))
  final DateTime moment;
  @Field(form: FormOptions(widget: FieldWidget.dropdown))
  final Status status;
  @Field(form: FormOptions(widget: FieldWidget.toggle))
  final bool active;
  WidgetDemo({
    this.id,
    required this.auto,
    required this.notes,
    required this.secret,
    required this.quantity,
    required this.day,
    required this.at,
    required this.moment,
    required this.status,
    required this.active,
  });
  factory WidgetDemo.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
