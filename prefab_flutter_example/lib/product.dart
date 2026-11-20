import 'package:json_annotation/json_annotation.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

part 'product.g.dart';

/// An enum field: the form uses a dropdown, the detail screen shows its name.
enum ProductCategory { electronics, office, accessories }

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

  /// Optional enum field: dropdown with an empty option.
  @Field(sortable: true)
  final ProductCategory? category;

  /// Multi-line text with a length validator, shown on the detail view only.
  @Field(
    views: {'detail'},
    form: FormOptions(
      widget: FieldWidget.multilineText,
      validators: [Validator.maxLength(200)],
    ),
  )
  final String? description;

  /// Optional date, edited with a date picker.
  @Field(label: 'Released on')
  final DateTime? releasedOn;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.inStock,
    this.category,
    this.description,
    this.releasedOn,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
