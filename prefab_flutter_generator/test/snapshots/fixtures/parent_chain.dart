import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Order', path: 'orders')
class Order {
  final int id;
  final String number;
  Order({required this.id, required this.number});
  factory Order.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}

@View(title: 'Order Line', path: 'lines')
@Create()
@Update()
@Delete()
class OrderLine {
  final int? id;
  @Parent(Order)
  @Field(hidden: true)
  final int orderId;
  @Field()
  final String product;
  OrderLine({this.id, required this.orderId, required this.product});
  factory OrderLine.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}

@View(title: 'Note', path: 'notes')
@Create()
@Update()
@Delete()
class OrderLineNote {
  final int? id;
  @Parent(OrderLine)
  @Field(hidden: true)
  final int orderLineId;
  @Field()
  final String text;
  OrderLineNote({this.id, required this.orderLineId, required this.text});
  factory OrderLineNote.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
