import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Products', path: 'products')
@Update()
@Delete()
class Product {
  final int id;

  @FormField(label: 'Name', validators: [Validator.required])
  final String name;

  @FormField(label: 'Price', validators: [Validator.required, Validator.positiveNumber])
  final double price;

  @FormField(label: 'Description', widget: FieldWidget.multilineText)
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
  });
}
