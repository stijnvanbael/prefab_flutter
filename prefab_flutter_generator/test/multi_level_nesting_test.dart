import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

const _prefabSources = {
  'prefab_flutter|lib/prefab_flutter.dart': r'''
export 'src/annotations/view.dart';
export 'src/annotations/update.dart';
export 'src/annotations/delete.dart';
export 'src/annotations/field.dart';
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
  'prefab_flutter|lib/src/annotations/field.dart': r'''
import 'package:prefab_flutter/src/enums/field_widget.dart';
import 'package:prefab_flutter/src/enums/validator.dart';
class FormOptions {
  final FieldWidget widget;
  final List<Validator> validators;
  const FormOptions({
    this.widget = FieldWidget.auto,
    this.validators = const [],
  });
}
class Field {
  final String? label;
  final bool hidden;
  final FormOptions form;
  const Field({
    this.label,
    this.hidden = false,
    this.form = const FormOptions(),
  });
}
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
enum FieldWidget { auto, multilineText, password, datePicker, timePicker, dateTimePicker, dropdown, toggle }
''',
  'prefab_flutter|lib/src/enums/validator.dart': r'''
/// Validation rules that the form-screen generator wires into form fields.
///
/// Parameterless rules are available as static constants
/// (`Validator.required`, `Validator.email`, ...); rules that carry a value are
/// created with the const factories (`Validator.min(0)`,
/// `Validator.pattern(r'^[A-Z]+$')`).
///
/// Every rule accepts an optional custom error [message]. For the parameterless
/// rules use the subclass constructor, e.g. `EmailValidator(message: 'Bad')`.
sealed class Validator {
  /// Custom error message shown instead of the default one.
  final String? message;

  const Validator({this.message});

  /// Field must not be empty (or, on dropdowns, must have a selection).
  static const Validator required = RequiredValidator();

  /// Field value must be a valid e-mail address.
  static const Validator email = EmailValidator();

  /// Field value must be a parseable absolute URL.
  static const Validator url = UrlValidator();

  /// Field value must be a number greater than zero.
  static const Validator positive = PositiveValidator();

  /// Alias of [positive], kept for backwards compatibility.
  static const Validator positiveNumber = PositiveValidator();

  /// Field value must be a number greater than or equal to zero.
  static const Validator nonNegative = NonNegativeValidator();

  /// Field value must be a number greater than or equal to [value].
  const factory Validator.min(num value, {String? message}) = MinValidator;

  /// Field value must be a number less than or equal to [value].
  const factory Validator.max(num value, {String? message}) = MaxValidator;

  /// Field value must be at least [length] characters long.
  const factory Validator.minLength(int length, {String? message}) =
      MinLengthValidator;

  /// Field value must be at most [length] characters long.
  const factory Validator.maxLength(int length, {String? message}) =
      MaxLengthValidator;

  /// Field value must match the regular expression [regex].
  const factory Validator.pattern(String regex, {String? message}) =
      PatternValidator;
}

/// See [Validator.required].
final class RequiredValidator extends Validator {
  const RequiredValidator({super.message});
}

/// See [Validator.email].
final class EmailValidator extends Validator {
  const EmailValidator({super.message});
}

/// See [Validator.url].
final class UrlValidator extends Validator {
  const UrlValidator({super.message});
}

/// See [Validator.positive].
final class PositiveValidator extends Validator {
  const PositiveValidator({super.message});
}

/// See [Validator.nonNegative].
final class NonNegativeValidator extends Validator {
  const NonNegativeValidator({super.message});
}

/// See [Validator.min].
final class MinValidator extends Validator {
  final num value;
  const MinValidator(this.value, {super.message});
}

/// See [Validator.max].
final class MaxValidator extends Validator {
  final num value;
  const MaxValidator(this.value, {super.message});
}

/// See [Validator.minLength].
final class MinLengthValidator extends Validator {
  final int length;
  const MinLengthValidator(this.length, {super.message});
}

/// See [Validator.maxLength].
final class MaxLengthValidator extends Validator {
  final int length;
  const MaxLengthValidator(this.length, {super.message});
}

/// See [Validator.pattern].
final class PatternValidator extends Validator {
  final String regex;
  const PatternValidator(this.regex, {super.message});
}
''',
};

const _source = r"""
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Order', path: 'orders')
class Order {
  final int id;
  @Field(label: 'Number')
  final String number;
  Order({required this.id, required this.number});
  factory Order.fromJson(Map<String, dynamic> json) => Order(id: 1, number: '');
  Map<String, dynamic> toJson() => {};
}

@View(title: 'Order Line', path: 'lines')
@Update()
@Delete()
class OrderLine {
  final int? id;
  @Parent(Order)
  @Field(hidden: true)
  final int orderId;
  @Field(label: 'Product')
  final String product;
  OrderLine({this.id, required this.orderId, required this.product});
  factory OrderLine.fromJson(Map<String, dynamic> json) =>
      OrderLine(orderId: 1, product: '');
  Map<String, dynamic> toJson() => {};
}

@View(title: 'Note', path: 'notes')
@Update()
@Delete()
class OrderLineNote {
  final int? id;
  @Parent(OrderLine)
  @Field(hidden: true)
  final int orderLineId;
  @Field(label: 'Text')
  final String text;
  OrderLineNote({this.id, required this.orderLineId, required this.text});
  factory OrderLineNote.fromJson(Map<String, dynamic> json) =>
      OrderLineNote(orderLineId: 1, text: '');
  Map<String, dynamic> toJson() => {};
}
""";

const _cycleSource = r"""
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'A', path: 'as')
class A {
  final int id;
  @Parent(B)
  @Field()
  final int bId;
  A({required this.id, required this.bId});
}

@View(title: 'B', path: 'bs')
class B {
  final int id;
  @Parent(A)
  @Field()
  final int aId;
  B({required this.id, required this.aId});
}
""";

Future<void> _expect(Builder builder, String output, List<String> expected,
    {String source = _source, String file = 'order'}) async {
  await testBuilder(
    builder,
    {
      ...Map<String, Object>.from(_prefabSources),
      'a|lib/$file.dart': source,
    },
    outputs: {
      'a|lib/$file.$output.dart': decodedMatches(
        predicate<String>((s) {
          final flat = s.replaceAll(RegExp(r'\s+'), '');
          final missing = expected
              .where((e) => !flat.contains(e.replaceAll(RegExp(r'\s+'), '')))
              .toList();
          if (missing.isNotEmpty) printOnFailure('missing: $missing\n$s');
          return missing.isEmpty;
        }, 'contains $expected'),
      ),
    },
  );
}

void main() {
  group('Multi-level nesting (PF-19)', () {
    test('routes nest three levels with unique path parameters', () async {
      await _expect(routesBuilder(BuilderOptions.empty), 'routes', [
        "path: '/orders'",
        "path: ':orderId'",
        "path: 'lines'",
        "path: ':orderLineId'",
        "path: 'notes'",
        "OrderLineNoteListScreen(orderId: int.parse(state.pathParameters['orderId']!), orderLineId: int.parse(state.pathParameters['orderLineId']!))",
        "OrderLineNoteDetailScreen(id: int.parse(state.pathParameters['id']!), orderId: int.parse(state.pathParameters['orderId']!), orderLineId: int.parse(state.pathParameters['orderLineId']!))",
        "OrderLineNoteCreateScreen(orderId: int.parse(state.pathParameters['orderId']!), orderLineId: int.parse(state.pathParameters['orderLineId']!))",
      ]);
    });

    test('api client injects every ancestor id into the URL', () async {
      await _expect(apiClientBuilder(BuilderOptions.empty), 'api_client', [
        'Future<PrefabPage<OrderLineNote>> list({required int orderId, required int orderLineId,',
        r"_dio.get('/orders/$orderId/lines/$orderLineId/notes'",
        'Future<OrderLineNote> getById(int id, {required int orderId, required int orderLineId})',
        'Future<OrderLineNote> create(OrderLineNote orderLineNote, {required int orderId, required int orderLineId})',
        r"_dio.delete('/orders/$orderId/lines/$orderLineId/notes/${orderLineNote.id}')",
      ]);
    });

    test('providers thread all ancestor ids', () async {
      await _expect(providerBuilder(BuilderOptions.empty), 'provider', [
        'final orderLineNoteDetailProvider = FutureProvider.autoDispose.family<OrderLineNote, (int, int, int)>',
        r'getById(args.$1, orderId: args.$2, orderLineId: args.$3)',
        'AutoDisposeFamilyAsyncNotifier<PrefabPage<OrderLineNote>, (int, int)>',
        r'int get orderId => arg.$1;',
        r'int get orderLineId => arg.$2;',
        'FutureOr<PrefabPage<OrderLineNote>> build((int, int) arg)'
            .replaceFirst('FutureOr', 'Future'),
        '_client.list(orderId: orderId, orderLineId: orderLineId,',
        '_client.create(orderLineNote, orderId: orderId, orderLineId: orderLineId)',
        'ref.invalidate(orderLineNoteDetailProvider((orderLineNote.id!, orderId, orderLineId)))',
      ]);
    });

    test('list screen takes all ancestor ids and shows a breadcrumb', () async {
      await _expect(listScreenBuilder(BuilderOptions.empty), 'list_screen', [
        'const OrderLineNoteListScreen({super.key, required this.orderId, required this.orderLineId})',
        'ref.watch(orderLineNotesProvider((orderId, orderLineId)))',
        'bottom: PrefabBreadcrumbBar(',
        "ref.watch(orderDetailProvider(orderId)).valueOrNull?.number.toString() ?? '…'",
        "ref.watch(orderLineDetailProvider((orderLineId, orderId))).valueOrNull?.product.toString() ?? '…'",
        r"context.go('/orders/$orderId')",
        r"context.go('/orders/$orderId/lines/$orderLineId')",
        r"context.push('/orders/$orderId/lines/$orderLineId/notes/${orderLineNote.id}')",
      ]);
    });

    test('detail screen shows a breadcrumb; depth two has none', () async {
      await _expect(detailScreenBuilder(BuilderOptions.empty), 'detail_screen', [
        'bottom: PrefabBreadcrumbBar(',
        "const PrefabBreadcrumb(label: 'Note')",
        'ref.watch(orderLineNoteDetailProvider((id, orderId, orderLineId)))',
        'ref.read(orderLineNotesProvider((orderId, orderLineId)).notifier).delete(orderLineNote)',
        r"context.push('/orders/$orderId/lines/$orderLineId/notes/$id/edit')",
      ]);
      // OrderLine has a single ancestor: no breadcrumb row.
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        {
          ...Map<String, Object>.from(_prefabSources),
          'a|lib/order.dart': _source,
        },
        outputs: {
          'a|lib/order.detail_screen.dart': decodedMatches(
            predicate<String>((s) {
              final start = s.indexOf('class OrderLineDetailScreen');
              final end = s.indexOf('class OrderLineNoteDetailScreen');
              return !s.substring(start, end).contains('PrefabBreadcrumbBar');
            }, 'OrderLineDetailScreen has no breadcrumb'),
          ),
        },
      );
    });

    test('form screens take and thread all ancestor ids', () async {
      await _expect(formScreenBuilder(BuilderOptions.empty), 'form_screen', [
        'const OrderLineNoteEditScreen({super.key, required this.id, required this.orderId, required this.orderLineId})',
        'ref.watch(orderLineNoteDetailProvider((widget.id, widget.orderId, widget.orderLineId)))',
        'orderLineNotesProvider((widget.orderId, widget.orderLineId))',
      ]);
    });

    test('circular @Parent chains are an error', () async {
      final logs = <String>[];
      Object? error;
      try {
        await testBuilder(
          routesBuilder(BuilderOptions.empty),
          {
            ...Map<String, Object>.from(_prefabSources),
            'a|lib/cycle.dart': _cycleSource,
          },
          outputs: {},
          onLog: (r) => logs.add(r.message),
        );
      } catch (e) {
        error = e;
      }
      expect('$error\n${logs.join('\n')}', contains('Circular @Parent chain'));
    });
  });
}
