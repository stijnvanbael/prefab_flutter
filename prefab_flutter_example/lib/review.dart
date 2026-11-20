import 'package:json_annotation/json_annotation.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

import 'product.dart';

part 'review.g.dart';

@JsonSerializable()
@View()
@Create()
@Update()
@Delete()
class Review {
  final int? id;

  @Field()
  @Parent(Product)
  final int productId;

  @Field(form: FormOptions(validators: [Validator.required]))
  final String comment;

  /// Optional 1-5 rating: a number input with range validators.
  @Field(
    form: FormOptions(
      widget: FieldWidget.numberInput,
      validators: [Validator.min(1), Validator.max(5)],
    ),
  )
  final int? rating;

  Review({
    this.id,
    required this.productId,
    required this.comment,
    this.rating,
  });

  factory Review.fromJson(Map<String, dynamic> json) =>
      _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}
