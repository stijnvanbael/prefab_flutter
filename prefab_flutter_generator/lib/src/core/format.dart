import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

// dart_style is pinned to one minor version (see pubspec.yaml) and formats for
// a fixed language version, so the output changes neither with the SDK nor
// with the language version of the user's package. 3.0 keeps the classic
// (short) style; raising it is a deliberate change that regenerates snapshots.
final _languageVersion = Version(3, 0, 0);

/// Formats an assembled library with `dart_style`, so fragments need not be
/// indented exactly. Throws a [FormatException] naming [sourceFileName] and
/// containing the unformatted [source] when it does not parse (a template bug).
String formatGenerated(String source, String sourceFileName) {
  if (source.isEmpty) return source;
  try {
    return DartFormatter(languageVersion: _languageVersion).format(source);
  } on FormatterException catch (e) {
    throw FormatException(
      'The code generated for $sourceFileName is not valid Dart:\n'
      '${e.message()}\n'
      '--- unformatted output ---\n$source',
    );
  }
}
