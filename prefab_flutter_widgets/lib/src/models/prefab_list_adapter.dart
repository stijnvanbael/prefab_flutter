import 'prefab_backend.dart';

/// The former list adapter, now [PrefabBackend].
///
/// It keeps the previous defaults (the Simple preset: `sort=-field` and
/// `{ "items", "total" }`), so existing code keeps working.
@Deprecated('Use PrefabBackend (PrefabBackend.simple() for this contract).')
class PrefabListAdapter extends PrefabBackend {
  const PrefabListAdapter({
    super.searchParam,
    super.sortParam,
    super.pageParam,
    super.sizeParam,
    super.itemsKey = 'items',
    super.totalKey = 'total',
    super.defaultPageSize,
  }) : super.simple();
}

/// Use [prefabBackendProvider].
@Deprecated('Use prefabBackendProvider.')
final prefabListAdapterProvider = prefabBackendProvider;
