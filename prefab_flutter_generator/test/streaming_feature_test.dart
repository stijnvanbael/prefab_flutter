import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

String _source({required bool streaming}) => '''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Device', path: 'devices')
${streaming ? '@Streaming()' : ''}
class Device {
  final int id;
  @Field()
  final String name;
  Device({required this.id, required this.name});
  factory Device.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

Future<void> _expectOutput(bool streaming, Matcher matcher) => testBuilder(
      prefabBuilder(BuilderOptions.empty),
      {...prefabSources, 'a|lib/device.dart': _source(streaming: streaming)},
      outputs: {'a|lib/device.prefab.dart': decodedMatches(matcher)},
    );

void main() {
  group('PF-56 AC#1 - @Streaming opts an entity in', () {
    test('the providers follow the event stream', () async {
      await _expectOutput(
        true,
        allOf([
          contains('String eventsUrl() =>'),
          contains('StreamProvider.autoDispose'),
          contains('prefabLiveDetail<Device>'),
          contains('prefabEventsProvider(_client.eventsUrl())'),
          contains('applyPrefabEvent<Device>'),
          contains('Future<void> reload() => _load();'),
          contains('PrefabNewItemsBanner('),
          contains('.read(devicesProvider.notifier)'),
        ]),
      );
    });

    test('an entity without @Streaming is unchanged', () async {
      await _expectOutput(
        false,
        allOf([
          contains('FutureProvider.autoDispose'),
          isNot(contains('eventsUrl')),
          isNot(contains('prefabEventsProvider')),
          isNot(contains('PrefabNewItemsBanner')),
        ]),
      );
    });
  });
}
