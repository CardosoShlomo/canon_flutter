import 'package:flutter/widgets.dart';

import 'package:canon/canon.dart';

/// The item-level sibling of `ScreenScope`: planted in a list's `itemBuilder`,
/// it scopes ONE entity (id + live data) to the item's subtree.
///
/// ```dart
/// itemBuilder: (context, index) => EntityScope(adsStore, ids[index], child: AdCard())
/// ```
///
/// - **Ambient identity below the screen**: the subtree reads its entity via
///   [of] / its id via [idOf] — no threading through constructors.
/// - **Surgical rebuilds**: the scope subscribes to the store's per-key
///   [StoreMemory.changes] for exactly its id — the list's own build can watch
///   length only, and a per-entity update rebuilds one item, not the list.
/// - **Identity-stable keys**: key list items by the entity id
///   (`key: ValueKey(id)`), never by index.
final class EntityScope<K, E extends Identifiable<K>> extends StatefulWidget {
  const EntityScope(this.store, this.id, {super.key, required this.child});

  /// The store the entity lives in (any message type — read-only here).
  final StoreMemory<K, E, Msg> store;

  final K id;
  final Widget child;

  /// The ambient entity of this item subtree. [E] is the caller's assertion —
  /// the nearest scope must hold that entity type.
  static E of<E>(BuildContext context) {
    final entry = context.dependOnInheritedWidgetOfExactType<_EntityEntry>();
    assert(entry != null, 'no EntityScope above this context');
    return entry!.entity as E;
  }

  /// The ambient entity's id.
  static K idOf<K>(BuildContext context) {
    final entry = context.dependOnInheritedWidgetOfExactType<_EntityEntry>();
    assert(entry != null, 'no EntityScope above this context');
    return entry!.id as K;
  }

  @override
  State<EntityScope<K, E>> createState() => _EntityScopeState<K, E>();
}

final class _EntityScopeState<K, E extends Identifiable<K>>
    extends State<EntityScope<K, E>> {
  StreamSubscription<K>? _sub;
  late E _entity;

  @override
  void initState() {
    super.initState();
    _read();
    _listen();
  }

  @override
  void didUpdateWidget(EntityScope<K, E> old) {
    super.didUpdateWidget(old);
    if (old.store != widget.store || old.id != widget.id) {
      _sub?.cancel();
      _read();
      _listen();
    }
  }

  // A removed entity keeps its last value: removal is the OWNING LIST's fact
  // (its length changes and the item unmounts); the scope never flashes null.
  void _read() => _entity = widget.store[widget.id] ?? _entity;

  void _listen() => _sub = widget.store.changes
      .where((k) => k == widget.id)
      .listen((_) => setState(_read));

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _EntityEntry(entity: _entity, id: widget.id, child: widget.child);
}

final class _EntityEntry extends InheritedWidget {
  const _EntityEntry(
      {required this.entity, required this.id, required super.child});

  final Object entity;
  final Object? id;

  @override
  bool updateShouldNotify(_EntityEntry old) => !identical(entity, old.entity);
}
