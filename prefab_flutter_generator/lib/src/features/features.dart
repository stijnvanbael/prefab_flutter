import '../core/feature.dart';
import 'actions/actions_feature.dart';
import 'breadcrumbs/breadcrumbs_feature.dart';
import 'create/create_feature.dart';
import 'custom_field/custom_field_feature.dart';
import 'delete/delete_feature.dart';
import 'entity_screens/entity_screens_feature.dart';
import 'field_widgets/field_widgets_feature.dart';
import 'list_query/list_query_feature.dart';
import 'nested_resources/nested_resources_feature.dart';
import 'nullable_fields/nullable_fields_feature.dart';
import 'update/update_feature.dart';
import 'validators/validators_feature.dart';
import 'views/views_feature.dart';

/// Every feature module, alphabetical by directory name. Add one line when
/// you add a feature; the order has no meaning (contributions are ordered by
/// their `order`, then feature name).
const registeredFeatures = <Feature>[
  ActionsFeature(),
  BreadcrumbsFeature(),
  CreateFeature(),
  CustomFieldFeature(),
  DeleteFeature(),
  EntityScreensFeature(),
  FieldWidgetsFeature(),
  ListQueryFeature(),
  NestedResourcesFeature(),
  NullableFieldsFeature(),
  UpdateFeature(),
  ValidatorsFeature(),
  ViewsFeature(),
];
