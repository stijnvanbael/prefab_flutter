import 'package:dart_style/dart_style.dart';

// dart_style is pinned to one exact version (see pubspec.yaml) so the output
// does not change with the SDK the user builds with. dart_style 2.3.6 has no
// `languageVersion` parameter; pinning one needs dart_style >= 2.3.7, which
// needs analyzer >= 6.5 (blocked by source_gen 1.x on current SDKs, PF-43).

/// Formats an assembled library with `dart_style`, so fragments need not be
/// indented exactly. Throws a [FormatException] naming [sourceFileName] and
/// containing the unformatted [source] when it does not parse (a template bug).
String formatGenerated(String source, String sourceFileName) {
  if (source.isEmpty) return source;
  try {
    return DartFormatter().format(source);
  } on FormatterException catch (e) {
    throw FormatException(
      'The code generated for $sourceFileName is not valid Dart:\n'
      '${e.message()}\n'
      '--- unformatted output ---\n$source',
    );
  }
}
