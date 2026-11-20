import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

DioException _dioError(int status, Object? data) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: data,
      ),
    );

void main() {
  group('PrefabBackend.parseError', () {
    test('Prefab preset reads Problem Details with a field list', () {
      final error = const PrefabBackend().parseError(_dioError(422, {
        'title': 'Invalid',
        'detail': 'The product is invalid.',
        'errors': [
          {'field': 'name', 'message': 'must not be blank'},
          {'field': 'unit_price', 'message': 'must be positive'},
        ],
      }));
      expect(error.status, 422);
      expect(error.isValidation, isTrue);
      expect(error.message, 'The product is invalid.');
      expect(error.fieldErrors, {
        'name': 'must not be blank',
        'unit_price': 'must be positive',
      });
    });

    test('Simple preset reads message and a field map', () {
      final error = const PrefabBackend.simple().parseError(_dioError(400, {
        'message': 'Bad',
        'errors': {
          'name': ['too short', 'no digits'],
        },
      }));
      expect(error.message, 'Bad');
      expect(error.fieldErrors, {'name': 'too short\nno digits'});
    });

    test('title is the fallback message; 404 and 409 are recognised', () {
      final notFound = const PrefabBackend()
          .parseError(_dioError(404, {'title': 'Not Found'}));
      expect(notFound.isNotFound, isTrue);
      expect(notFound.message, 'Not Found');
      expect(
        const PrefabBackend().parseError(_dioError(409, null)).isConflict,
        isTrue,
      );
    });

    test('keys are configurable', () {
      final error = const PrefabBackend(
        errorMessageKey: 'msg',
        errorsKey: 'violations',
        errorFieldKey: 'path',
        errorFieldMessageKey: 'text',
      ).parseError(_dioError(422, {
        'msg': 'No',
        'violations': [
          {'path': 'a', 'text': 'bad'},
        ],
      }));
      expect(error.message, 'No');
      expect(error.fieldErrors, {'a': 'bad'});
    });

    test('other errors have no status', () {
      final error = const PrefabBackend().parseError(StateError('boom'));
      expect(error.status, isNull);
      expect(error.message, contains('boom'));
    });
  });

  group('form error widgets', () {
    testWidgets('show field and general errors; editing clears the field',
        (tester) async {
      final errors = PrefabFormErrors();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            onChanged: errors.clearEdited,
            child: Column(children: [
              PrefabFormErrorBanner(errors: errors),
              PrefabFieldError(
                errors: errors,
                field: 'name',
                children: [TextFormField(key: const Key('name'))],
              ),
              PrefabFieldError(
                errors: errors,
                field: 'price',
                children: [TextFormField(key: const Key('price'))],
              ),
            ]),
          ),
        ),
      ));

      errors.setError(
        const PrefabApiError(
          status: 422,
          message: 'Invalid',
          fieldErrors: {'name': 'taken', 'price': 'too high', 'x': 'unknown'},
        ),
        const {'name', 'price'},
      );
      await tester.pump();
      expect(find.text('taken'), findsOneWidget);
      expect(find.text('too high'), findsOneWidget);
      expect(find.text('Invalid'), findsOneWidget);
      expect(find.text('x: unknown'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('name')), 'new');
      await tester.pump();
      expect(find.text('taken'), findsNothing);
      expect(find.text('too high'), findsOneWidget);
    });
  });

  testWidgets('default not-found builder offers a way back', (tester) async {
    var back = false;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => PrefabTheme.of(context)
            .notFoundBuilder(context, () => back = true),
      ),
    ));
    await tester.tap(find.text('Back to list'));
    expect(back, isTrue);
  });
}
