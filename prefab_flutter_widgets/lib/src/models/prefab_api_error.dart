/// A failed request, parsed by [PrefabBackend.parseError]: the HTTP status,
/// a general message and the validation messages by JSON field name.
class PrefabApiError implements Exception {
  const PrefabApiError({
    this.status,
    this.message,
    this.fieldErrors = const {},
    this.cause,
  });

  /// The HTTP status, or `null` when there was no response (network failure).
  final int? status;

  /// The general message of the response (`detail`, `title` or `message`), or
  /// the text of the underlying error.
  final String? message;

  /// Validation messages by JSON field name (the `@JsonKey(name:)` value, the
  /// `fieldRename` applied name or the Dart name). Generated forms map them
  /// back to the Dart fields.
  final Map<String, String> fieldErrors;

  /// The error this one was parsed from, e.g. a `DioException`.
  final Object? cause;

  /// The resource does not exist (404).
  bool get isNotFound => status == 404;

  /// The resource changed since it was read (409).
  bool get isConflict => status == 409;

  /// The server rejected the request as invalid (400 or 422).
  bool get isValidation => status == 400 || status == 422;

  @override
  String toString() =>
      message ?? (status == null ? 'Request failed' : 'Request failed ($status)');
}
