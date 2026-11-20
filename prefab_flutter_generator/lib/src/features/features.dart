import '../core/feature.dart';
import 'actions/actions_feature.dart';
import 'entity_screens/entity_screens_feature.dart';
import 'field_widgets/field_widgets_feature.dart';
import 'list_query/list_query_feature.dart';
import 'nullable_fields/nullable_fields_feature.dart';
import 'validators/validators_feature.dart';

/// Every feature module, alphabetical by directory name. Add one line when
/// you add a feature; the order has no meaning (contributions are ordered by
/// their `order`, then feature name).
const registeredFeatures = <Feature>[
  ActionsFeature(),
  EntityScreensFeature(),
  FieldWidgetsFeature(),
  ListQueryFeature(),
  NullableFieldsFeature(),
  ValidatorsFeature(),
];
