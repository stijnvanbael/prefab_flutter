import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Account', path: 'accounts')
@Create()
@Update()
class Account {
  final int? id;
  @Field(form: FormOptions(validators: [Validator.required, Validator.email]))
  final String email;
  @Field(form: FormOptions(validators: [Validator.minLength(3), Validator.maxLength(20, message: 'Too long')]))
  final String username;
  @Field(form: FormOptions(validators: [Validator.pattern(r'^[A-Z]+$')]))
  final String code;
  @Field(form: FormOptions(validators: [Validator.min(1, message: "Can't be < 1"), Validator.max(99)]))
  final int age;
  @Field(form: FormOptions(validators: [Validator.url]))
  final String? website;
  Account({
    this.id,
    required this.email,
    required this.username,
    required this.code,
    required this.age,
    this.website,
  });
  factory Account.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
