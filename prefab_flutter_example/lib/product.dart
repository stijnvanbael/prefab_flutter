import 'package:json_annotation/json_annotation.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

part 'product.g.dart';

/// An enum field: the form uses a dropdown, the detail screen shows its name.
enum ProductCategory { electronics, office, accessories }

/// The parameters of the `discount` operation of [Product] (PF-54): a form
/// with these fields opens, and its JSON is the request body. It is a plain
/// class: only `toJson()` is needed.
class DiscountParameters {
  @Field(
    label: 'Percent',
    form: FormOptions(validators: [Validator.min(1), Validator.max(90)]),
  )
  final int percent;

  @Field(label: 'Reason')
  final String? reason;

  const DiscountParameters({required this.percent, this.reason});

  Map<String, dynamic> toJson() => {'percent': percent, 'reason': reason};
}

@JsonSerializable()
@Entity(title: 'Product', path: 'products')
@Create()
@Update()
@Delete()
// Named operations (PF-54): `POST /products/{id}/discontinue` and
// `POST /products/{id}/discount`, in the menu of each list item. The first has
// no parameters and runs after a confirmation, the second opens a form.
@Update(
  path: 'discontinue',
  label: 'Discontinue',
  icon: 'block',
  confirm: 'Mark this product as out of stock?',
  on: {Place.item},
)
@Update(
  path: 'discount',
  label: 'Discount',
  icon: 'percent',
  parameters: DiscountParameters,
  on: {Place.item},
)
class Product {
  final int? id;

  /// Optimistic locking: the server rejects an update of an outdated version
  /// with 409, and the edit screen offers to reload (PF-52). Never a form field.
  @Version()
  final int? version;

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

  /// Multi-line text with a length validator, shown on the detail screen and
  /// in the form but not in the list (`on:`).
  @Field(
    on: {Place.detail, Place.form},
    form: FormOptions(
      widget: FieldWidget.multilineText,
      validators: [Validator.maxLength(200)],
    ),
  )
  final String? description;

  /// Optional date, edited with a date picker.
  @Field(label: 'Released on')
  final DateTime? releasedOn;

  /// Create-only (PF-53): set in the create form, absent from the edit form and
  /// from the body of the update request.
  @Field(label: 'SKU', form: FormOptions(on: {FormMode.create}))
  final String? sku;

  /// Server-set (PF-53): shown in the list and detail screens, never in a form
  /// or in the body of a create or update request.
  @Field(label: 'Created at', readOnly: true)
  final DateTime createdAt;

  Product({
    this.id,
    this.version,
    required this.name,
    required this.price,
    required this.inStock,
    this.category,
    this.description,
    this.releasedOn,
    this.sku,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
