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

  Review({this.id, required this.productId, required this.comment});

  factory Review.fromJson(Map<String, dynamic> json) =>
      _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}
