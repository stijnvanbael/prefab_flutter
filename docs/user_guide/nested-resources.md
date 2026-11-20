[← User guide](../user_guide.md)

# Nested resources

An entity with a `@Parent` field is shown under its parent:

```dart
@Entity(title: 'Post', path: 'posts')
class Post {
  final int? id;
  @Field() final String title;
  Post({this.id, required this.title});
}

@Entity(title: 'Comment', path: 'comments')
class Comment {
  final int? id;
  @Field() @Parent(Post) final int postId;
  @Field() final String body;
  Comment({this.id, required this.postId, required this.body});
}
```

Rules:

- `@Parent(Post)` names the parent entity explicitly. The parent must carry a
  `@Entity` annotation (its `path` is used in routes and API URLs); otherwise the
  build fails.
- The parent may be declared in the same file or in **another source file**.
  A child whose parent lives in another file is registered as a top-level route
  (`/posts/:postId/comments`) in its own routes getter (e.g. `$commentRoutes`)
  instead of being nested inside the parent's route. Register both getters.
- The type of the `@Parent` field must equal the type of the parent's `id`
  field, otherwise the build fails.
- Chains can be arbitrarily deep (`Order` -> `OrderLine` -> `OrderLineNote`):
  every entity has one `@Parent`, and the whole ancestor chain is resolved from
  the `@Parent(Type)` references, across files. A circular chain fails the
  build.
- The parent field is not shown in forms or the detail screen.

Effects:

- Routes: `/posts/:postId/comments` and `/posts/:postId/comments/:id`.
- The API client calls `/posts/{postId}/comments[/{id}]`, and every method
  takes a named `postId` argument.
- `commentsProvider` is a family keyed on `postId`; `commentDetailProvider` is
  keyed on the record `(id, postId)`.

- `CommentCreateScreen` and `CommentEditScreen` take a required `postId`;
  the edit screen watches `commentDetailProvider((id, postId))`.
- The detail screen's Edit action opens `/posts/$postId/comments/$id/edit`, and
  its Delete action uses `commentsProvider(postId).notifier`.
- List and detail navigation paths are built by one shared helper, so they
  always match the routes.

### Deeper chains and breadcrumbs

For an entity nested more than one level deep, every ancestor id is threaded
through the generated code. With `OrderLineNote` (`@Parent(OrderLine)`),
`OrderLine` (`@Parent(Order)`, field `orderId`) and `Order`:

- Routes: `/orders/:orderId/lines/:orderLineId/notes[/:id]`. Each level has a
  unique path parameter named `<entity>Id`.
- The API client calls `/orders/{orderId}/lines/{orderLineId}/notes[/{id}]`;
  every method takes named `orderId` and `orderLineId` arguments. The direct
  parent's argument is named after the `@Parent` field, the other ancestors'
  after their entity (`<entity>Id`); these names must not clash.
- `orderLineNotesProvider` is a family keyed on the positional record
  `(orderId, orderLineId)` (outermost ancestor first; a single id when there
  is one ancestor); `orderLineNoteDetailProvider` is keyed on
  `(id, orderId, orderLineId)`.
- Screens take all ancestor ids as required constructor arguments.
- When an entity has **two or more ancestors**, its list and detail screens
  show a breadcrumb row in the AppBar (`PrefabBreadcrumbBar`): one tappable
  step per ancestor, labelled with the ancestor's first visible `@Field` value
  (from the ancestor's detail provider, `…` while loading), followed by the
  entity's own title. Tapping a step navigates to that ancestor's detail
  screen. Ancestors declared in another file need that file's `.prefab.dart`
  to be importable from the entity's generated file (it is imported
  automatically).
