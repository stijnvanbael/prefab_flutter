import 'package:json_annotation/json_annotation.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

import 'review.dart';

part 'reply.g.dart';

/// Third nesting level: Product -> Review -> Reply (PF-19).
@JsonSerializable()
@View(title: 'Reply', path: 'replies')
@Update()
@Delete()
class Reply {
  final int? id;

  @Field()
  @Parent(Review)
  final int reviewId;

  @Field(form: FormOptions(validators: [Validator.required]))
  final String text;

  Reply({this.id, required this.reviewId, required this.text});

  factory Reply.fromJson(Map<String, dynamic> json) => _$ReplyFromJson(json);
  Map<String, dynamic> toJson() => _$ReplyToJson(this);
}
