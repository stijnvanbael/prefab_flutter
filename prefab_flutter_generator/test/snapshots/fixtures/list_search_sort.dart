import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Book', path: 'books', paged: false)
class Book {
  final int id;
  @Field(searchable: true, sortable: true)
  final String title;
  @Field(sortable: true)
  final int pages;
  @Field(searchable: true)
  final String? author;
  Book({required this.id, required this.title, required this.pages, this.author});
  factory Book.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
