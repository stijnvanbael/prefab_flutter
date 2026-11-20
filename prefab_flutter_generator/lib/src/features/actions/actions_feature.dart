import '../../core/artifact.dart';
import '../../core/code.dart';
import '../../core/declarations.dart';
import '../../core/entity_context.dart';
import '../../core/feature.dart';
import '../../generators/detail_screen_generator.dart';
import '../../generators/list_screen_generator.dart';
import 'action_rendering.dart';
import 'action_scanner.dart';

/// Hand-written actions on the generated screens (`@EntityAction`).
///
/// The functions are found by the `prefab_declarations` builder (a summary per
/// file, like `@Promoted`) and arrive in [EntityContext.actions]. The feature
/// adds them to the detail screen (`appBarActions`), the list screen
/// (`appBarActions`) and each list item (`itemActions`), all at order 50.
/// A screen that is promoted is not in the `ArtifactSet`; the build warns
/// that it does not show the actions, and the `promote` command writes the
/// actions into the promoted file.
class ActionsFeature extends Feature {
  const ActionsFeature();

  static const _name = 'actions';
  static const _order = 50;

  @override
  String get name => _name;

  @override
  List<DeclarationScanner<Object>> get declarationScanners =>
      const [ActionsScanner.instance];

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    if (entity.actions.isEmpty) return;
    final id = entity.manifest.entityName;

    final detail =
        artifacts.get<DetailScreenArtifact>(ArtifactKind.detailScreen, id);
    final onDetail = _at(entity, 'detail');
    _warnPromoted(entity, artifacts, ArtifactKind.detailScreen, onDetail);
    if (detail != null && onDetail.isNotEmpty) {
      final items = sortActions([
        for (final a in onDetail)
          _item(a, '${a.name}(context, ref, ${detail.asyncName}.value!)'),
      ]);
      detail.appBarActions.add(
        _name,
        Code(
          renderAppBarActions(items,
              enabledWhen: '${detail.asyncName}.hasValue'),
          imports: _imports(onDetail),
        ),
        order: _order,
      );
    }

    final list =
        artifacts.get<ListScreenArtifact>(ArtifactKind.listScreen, id);
    _warnPromoted(entity, artifacts, ArtifactKind.listScreen,
        [..._at(entity, 'list'), ..._at(entity, 'item')]);
    if (list == null) return;
    final onList = _at(entity, 'list');
    if (onList.isNotEmpty) {
      final items = sortActions([
        for (final a in onList) _item(a, '${a.name}(context, ref)'),
      ]);
      list.appBarActions.add(
        _name,
        Code(renderAppBarActions(items), imports: _imports(onList)),
        order: _order,
      );
    }
    final onItem = _at(entity, 'item');
    if (onItem.isNotEmpty) {
      final items = sortActions([
        for (final a in onItem)
          _item(a, '${a.name}(context, ref, ${list.itemName})'),
      ]);
      list.itemActions.add(
        _name,
        Code(renderMenuEntries(items), imports: _imports(onItem)),
        order: _order,
      );
    }
  }

  void _warnPromoted(EntityContext entity, ArtifactSet artifacts,
      ArtifactKind kind, List<ActionDeclaration> actions) {
    final screen = artifacts.promotedName(kind, entity.manifest.entityName);
    if (screen == null || actions.isEmpty) return;
    artifacts.warn('$screen is @Promoted, so it does not show '
        '${actions.length == 1 ? 'the action' : 'the actions'} '
        '${[for (final a in actions) a.name].join(', ')} '
        '(@EntityAction on ${entity.manifest.entityName}). '
        'Add ${actions.length == 1 ? 'it' : 'them'} to $screen by hand.');
  }

  List<ActionDeclaration> _at(EntityContext entity, String place) =>
      [for (final a in entity.actions) if (a.places.contains(place)) a];

  ActionItem _item(ActionDeclaration a, String call) => ActionItem(
        label: a.label,
        icon: a.icon,
        call: call,
        order: a.order,
        name: a.name,
      );

  Set<String> _imports(List<ActionDeclaration> actions) =>
      {for (final a in actions) if (a.uri.isNotEmpty) a.uri};
}
