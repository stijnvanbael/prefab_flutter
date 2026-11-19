import 'package:json_annotation/json_annotation.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

part 'product.g.dart';

@JsonSerializable()
@View(title: 'Product', path: 'products')
@Create()
@Update()
@Delete()
class Product {
  final int? id;

  @Field(
    searchable: true,
    sortable: true,
    form: FormOptions(validators: [Validator.required]),
  )
  final String name;

  @Field(
    label: 'Price (EUR)',
    sortable: true,
    form: FormOptions(validators: [Validator.positive]),
  )
  final double price;

  @Field()
  final bool inStock;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.inStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
