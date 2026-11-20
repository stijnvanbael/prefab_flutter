[← User guide](../user_guide.md)

# Configuring the HTTP client

Every generated `{entity}ApiClientProvider` reads
`ref.watch(prefabDioProvider)`, and the generated provider file imports
`package:prefab_flutter_widgets/prefab_flutter_widgets.dart`. `prefabDioProvider`
has no default: reading it before it is overridden throws a descriptive
`UnimplementedError`. Override it once in your root `ProviderScope`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

void main() => runApp(
      ProviderScope(
        overrides: [
          prefabDioProvider.overrideWithValue(
            Dio(BaseOptions(baseUrl: 'https://api.example.com'))
              ..interceptors.add(MyAuthInterceptor()),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
```

`prefab_flutter_widgets` depends on `dio` (`>=5.4.0 <6.0.0`) and
`flutter_riverpod` (`>=2.5.0 <3.0.0`). The generated providers use the
`AsyncNotifier` API of Riverpod 2.x and no longer depend on the legacy
`StateNotifier`. Riverpod 3 is not supported yet because it removes the
`AutoDispose*` notifier base classes.
