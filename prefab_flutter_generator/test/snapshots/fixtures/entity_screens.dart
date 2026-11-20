import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Order', path: 'orders')
@Update()
class Order {
  final int id;
  @Field()
  final String? number;
  Order({required this.id, this.number});
  factory Order.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}

@View(title: 'Order Line', path: 'lines')
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
