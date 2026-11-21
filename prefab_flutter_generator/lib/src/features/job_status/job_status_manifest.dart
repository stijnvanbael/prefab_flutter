import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

final _jobStatusChecker =
    TypeChecker.typeNamed(JobStatus, inPackage: 'prefab_flutter');

/// The state names of `PrefabJobState`.
enum JobState { running, done, failed }

/// Enum value names (lower case, letters only) that classify a value when
/// `@JobStatus` does not name it.
const _inferredStates = <JobState, Set<String>>{
  JobState.running: {
    'queued',
    'pending',
    'waiting',
    'scheduled',
    'running',
    'inprogress',
    'started',
    'processing',
    'active',
  },
  JobState.done: {
    'done',
    'completed',
    'complete',
    'succeeded',
    'success',
    'finished',
    'ready',
  },
  JobState.failed: {'failed', 'failure', 'error', 'errored'},
};

/// Names of the `String?` field that holds the failure message when
/// `@JobStatus.message` does not name one, in order of preference.
const _inferredMessageFields = [
  'error',
  'errorMessage',
  'failureReason',
  'failureMessage',
  'failure',
];

/// The job status of an entity (`@JobStatus`, PF-57): the status field, which
/// enum values mean running, done and failed, the failure message field and
/// the poll interval.
class JobStatusManifest {
  const JobStatusManifest({
    required this.fieldName,
    required this.enumName,
    required this.enumLibraryUri,
    required this.states,
    required this.messageFieldName,
    required this.pollInterval,
  });

  /// The Dart name of the status field.
  final String fieldName;

  /// The name of the status enum.
  final String enumName;

  /// The library that declares the enum.
  final String enumLibraryUri;

  /// The state of every value of the enum, in declaration order.
  final Map<String, JobState> states;

  /// The `String?` field with the failure message, or `null`.
  final String? messageFieldName;

  final Duration pollInterval;

  /// The values of the enum that mean [state].
  List<String> valuesOf(JobState state) => [
        for (final e in states.entries)
          if (e.value == state) e.key,
      ];

  /// A boolean expression: whether `receiver.status` is running.
  String runningCondition(String receiver) => valuesOf(JobState.running)
      .map((v) => '$receiver.$fieldName == $enumName.$v')
      .join(' || ');

  /// An expression of type `PrefabJobState` for `receiver.status`.
  String stateExpression(String receiver) {
    final cases = [
      for (final state in JobState.values)
        if (valuesOf(state).isNotEmpty)
          '${valuesOf(state).map((v) => '$enumName.$v').join(' || ')} '
              '=> PrefabJobState.${state.name},',
    ];
    return 'switch ($receiver.$fieldName) {\n${cases.join('\n')}\n}';
  }

  /// An expression of type `String?` with the failure message of `receiver`,
  /// or `null` when the entity has none.
  String messageExpression(String receiver) =>
      messageFieldName == null ? 'null' : '$receiver.$messageFieldName';

  /// The job status of [entity], or `null` when no field has `@JobStatus`.
  /// Throws an [InvalidGenerationSourceError] for one that cannot be used.
  static JobStatusManifest? read(ClassElement entity) {
    final fields = [
      for (final f in entity.fields)
        if (!f.isStatic && _jobStatusChecker.hasAnnotationOf(f)) f,
    ];
    if (fields.isEmpty) return null;
    if (fields.length > 1) {
      throw InvalidGenerationSourceError(
        'Entity "${entity.name}" has more than one @JobStatus field.',
        element: entity,
      );
    }
    final field = fields.single;
    String problem(String what) =>
        '@JobStatus on "${entity.name}.${field.name}": $what';

    final type = field.type;
    final element = type.element;
    if (element is! EnumElement) {
      throw InvalidGenerationSourceError(
        problem('the field must be of an enum type, but is '
            '${type.getDisplayString()}.'),
        element: field,
      );
    }
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      throw InvalidGenerationSourceError(
        problem('the field must not be nullable: every job has a status.'),
        element: field,
      );
    }
    final annotation = _jobStatusChecker.firstAnnotationOf(field)!;
    final values = [
      for (final c in element.fields)
        if (c.isEnumConstant) c.name!,
    ];

    final states = <String, JobState>{};
    for (final state in JobState.values) {
      for (final name in _namesOf(annotation.getField(state.name))) {
        if (!values.contains(name)) {
          throw InvalidGenerationSourceError(
            problem('"$name" in ${state.name}: is not a value of '
                '${element.name}.'),
            element: field,
          );
        }
        final previous = states[name];
        if (previous != null && previous != state) {
          throw InvalidGenerationSourceError(
            problem('"$name" is in both ${previous.name} and ${state.name}.'),
            element: field,
          );
        }
        states[name] = state;
      }
    }
    final unclassified = <String>[];
    for (final value in values) {
      if (states.containsKey(value)) continue;
      final key = value.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
      final inferred = [
        for (final e in _inferredStates.entries)
          if (e.value.contains(key)) e.key,
      ];
      if (inferred.isEmpty) {
        unclassified.add(value);
      } else {
        states[value] = inferred.first;
      }
    }
    if (unclassified.isNotEmpty) {
      throw InvalidGenerationSourceError(
        problem('cannot tell what ${unclassified.map((v) => '"$v"').join(', ')} '
            'of ${element.name} mean. Name them in running:, done: or '
            'failed: of @JobStatus.'),
        element: field,
      );
    }
    final ordered = {for (final v in values) v: states[v]!};
    if (!ordered.values.contains(JobState.running)) {
      throw InvalidGenerationSourceError(
        problem('no value of ${element.name} means running. Name the values '
            'a job has while the server works on it in running:.'),
        element: field,
      );
    }

    final message = _messageField(entity, annotation, field, problem);
    // The field of `Duration` that holds the length was renamed between SDKs.
    final duration = annotation.getField('pollInterval');
    final micros = duration?.getField('inMicroseconds')?.toIntValue() ??
        duration?.getField('_duration')?.toIntValue();
    final interval = micros == null || micros <= 0
        ? const Duration(seconds: 3)
        : Duration(microseconds: micros);

    return JobStatusManifest(
      fieldName: field.name!,
      enumName: element.name!,
      enumLibraryUri: element.library.uri.toString(),
      states: ordered,
      messageFieldName: message,
      pollInterval: interval,
    );
  }

  static List<String> _namesOf(DartObject? set) {
    final values = set?.toSetValue();
    if (values == null) return const [];
    return [for (final v in values) v.variable!.name!];
  }

  static String? _messageField(
    ClassElement entity,
    DartObject annotation,
    FieldElement status,
    String Function(String) problem,
  ) {
    FieldElement? find(String name) => [
          for (final f in entity.fields)
            if (!f.isStatic && f.name == name) f,
        ].firstOrNull;

    final named = annotation.getField('message')?.toStringValue();
    if (named != null) {
      final field = find(named);
      if (field == null) {
        throw InvalidGenerationSourceError(
          problem('message: "$named" is not a field of "${entity.name}".'),
          element: status,
        );
      }
      if (field.type.getDisplayString().replaceAll('?', '') != 'String') {
        throw InvalidGenerationSourceError(
          problem('message: "$named" must be a String field.'),
          element: status,
        );
      }
      return named;
    }
    for (final name in _inferredMessageFields) {
      final field = find(name);
      if (field != null &&
          field.type.getDisplayString().replaceAll('?', '') == 'String') {
        return name;
      }
    }
    return null;
  }
}
