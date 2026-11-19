import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

const _prefabSources = {
  'prefab_flutter|lib/prefab_flutter.dart': r'''
export 'src/annotations/view.dart';
export 'src/annotations/update.dart';
export 'src/annotations/delete.dart';
export 'src/annotations/form_field.dart';
export 'src/annotations/parent.dart';
export 'src/enums/field_widget.dart';
export 'src/enums/validator.dart';
''',
  'prefab_flutter|lib/src/annotations/view.dart': r'''
class View {
  final String title;
  final String path;
  const View({required this.title, required this.path});
}
''',
  'prefab_flutter|lib/src/annotations/update.dart': r'''
class Update {
  const Update();
}
''',
  'prefab_flutter|lib/src/annotations/delete.dart': r'''
class Delete {
  const Delete();
}
''',
  'prefab_flutter|lib/src/annotations/form_field.dart': r'''
import 'package:prefab_flutter/src/enums/field_widget.dart';
import 'package:prefab_flutter/src/enums/validator.dart';
class FormField {
  final String? label;
  final FieldWidget widget;
  final List<Validator> validators;
  final bool hidden;
  const FormField({
    this.label,
    this.widget = FieldWidget.auto,
    this.validators = const [],
    this.hidden = false,
  });
}
''',
  'prefab_flutter|lib/src/annotations/parent.dart': r'''
class Parent {
  final Type type;
  const Parent(this.type);
}
''',
  'prefab_flutter|lib/src/enums/field_widget.dart': r'''
enum FieldWidget { auto, multilineText, password, datePicker, dropdown, toggle }
''',
  'prefab_flutter|lib/src/enums/validator.dart': r'''
enum Validator { required, email, positiveNumber, url }
''',
};

const _nestedSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Post', path: 'posts')
@Update()
@Delete()
class Post {
  final int id;

  @FormField(label: 'Title')
  final String title;

  Post({required this.id, required this.title});
}

@View(title: 'Comment', path: 'comments')
@Update()
@Delete()
class Comment {
  final int id;

  @Parent(Post)
  @FormField(hidden: true)
  final int postId;

  @FormField(label: 'Content')
  final String content;

  Comment({required this.id, required this.postId, required this.content});
}
''';

Map<String, Object> _assets() => {
      ...Map<String, Object>.from(_prefabSources),
      'a|lib/post.dart': _nestedSource,
    };

Future<void> _expect(
    Builder builder, String output, List<String> expected) async {
  await testBuilder(builder, _assets(), outputs: {
    'a|lib/post.$output.dart': decodedMatches(predicate<String>((s) {
      final flat = s.replaceAll(RegExp(r'\s+'), '');
      return expected
          .every((e) => flat.contains(e.replaceAll(RegExp(r'\s+'), '')));
    }, 'contains $expected')),
  });
}

void main() {
  group('Nested entity screens (PF-25)', () {
    test('create screen declares and requires the parent id', () async {
      await _expect(formScreenBuilder(BuilderOptions.empty), 'form_screen', [
        'class CommentCreateScreen extends ConsumerStatefulWidget',
        'final int postId;',
        'const CommentCreateScreen({super.key, required this.postId})',
      ]);
    });

    test(
        'edit screen requires the parent id and uses the (id, parentId) record',
        () async {
      await _expect(formScreenBuilder(BuilderOptions.empty), 'form_screen', [
        'const CommentEditScreen({super.key, required this.id, required this.postId})',
        'ref.watch(commentDetailProvider((widget.id, widget.postId)))',
      ]);
    });

    test('non-nested edit screen is unchanged', () async {
      await _expect(formScreenBuilder(BuilderOptions.empty), 'form_screen', [
        'const PostEditScreen({super.key, required this.id})',
        'ref.watch(postDetailProvider(widget.id))',
      ]);
    });

    test('detail screen Edit action navigates to the nested edit path',
        () async {
      await _expect(
          detailScreenBuilder(BuilderOptions.empty), 'detail_screen', [
        r"context.push('/posts/$postId/comments/$id/edit')",
        r"context.push('/posts/$id/edit')",
      ]);
    });

    test('detail screen Delete action uses the family list provider', () async {
      await _expect(
          detailScreenBuilder(BuilderOptions.empty), 'detail_screen', [
        'ref.read(commentsProvider(postId).notifier).delete(comment)',
        'ref.read(postsProvider.notifier).delete(post)',
      ]);
    });

    test('list screen navigates to the nested item path', () async {
      await _expect(listScreenBuilder(BuilderOptions.empty), 'list_screen',
          [r"context.push('/posts/$postId/comments/${comment.id}')"]);
    });
  });
}
