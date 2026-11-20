/// Takes over one generated artifact as hand-written code.
///
/// Declare a top-level class or variable with the artifact's name (for example
/// `ProductDetailScreen` or `productsProvider`) anywhere under `lib/` and
/// annotate it with [@Promoted]. The generator stops producing that artifact,
/// imports your declaration instead and re-exports it from the generated
/// `.prefab.dart` file, so all other generated code keeps working with it.
///
/// ```dart
/// @Promoted()
/// class ProductDetailScreen extends ConsumerWidget { ... }
/// ```
///
/// The declaration must keep the public signature of the generated artifact;
/// see the user guide ("Promoting generated code"). An annotated declaration
/// whose name is not a generated artifact fails the build and names the
/// closest artifact.
class Promoted {
  const Promoted();
}
