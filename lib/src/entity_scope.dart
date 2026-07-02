import 'package:flutter/foundation.dart';
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
  /// Self-keys by the entity id — identity-stable across index shifts, so the
  /// list may omit `key:` entirely.
  EntityScope(this.store, this.id, {Key? key, required this.child})
      : super(key: key ?? ValueKey(id));

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

  /// The ambient entity's OWN store — how a shared item widget acts on ITS
  /// list (two stores may hold the same entity kind).
  static S storeOf<S>(BuildContext context) {
    final entry = context.getInheritedWidgetOfExactType<_EntityEntry>();
    assert(entry != null, 'no EntityScope above this context');
    return entry!.store as S;
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
      _EntityEntry(
          entity: _entity,
          id: widget.id,
          store: widget.store,
          child: widget.child);
}

/// The collection half of the read-path: rebuilds ONLY when the store's key
/// SEQUENCE changes (add / remove / reorder). The builder receives ids — not
/// values — so list-level code cannot depend on entity data by construction;
/// each item wraps itself in an [EntityScope], which handles value changes
/// surgically. A value update rebuilds one item; the list build never re-runs.
///
/// ```dart
/// StoreBuilder(adsStore, (context, ids) => ListView(
///   children: [for (final id in ids) EntityScope(adsStore, id, child: AdCard())],
/// ))
/// ```
final class StoreBuilder<K, E extends Identifiable<K>> extends StatefulWidget {
  const StoreBuilder(this.store, this.builder, {super.key});

  final StoreMemory<K, E, Msg> store;
  final Widget Function(BuildContext context, List<K> ids) builder;

  @override
  State<StoreBuilder<K, E>> createState() => _StoreBuilderState<K, E>();
}

final class _StoreBuilderState<K, E extends Identifiable<K>>
    extends State<StoreBuilder<K, E>> {
  StreamSubscription<K>? _sub;
  late List<K> _ids;

  @override
  void initState() {
    super.initState();
    _ids = [...widget.store.entities.keys];
    _listen();
  }

  @override
  void didUpdateWidget(StoreBuilder<K, E> old) {
    super.didUpdateWidget(old);
    if (old.store != widget.store) {
      _sub?.cancel();
      _ids = [...widget.store.entities.keys];
      _listen();
    }
  }

  void _listen() => _sub = widget.store.changes.listen((_) {
        final next = [...widget.store.entities.keys];
        if (listEquals(next, _ids)) return; // value-only change → items handle it
        setState(() => _ids = next);
      });

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _ids);
}

/// Reactive ids read, no builder: `final ids = adsStore.of(context);` —
/// subscribes the widget to THIS store's key SEQUENCE (add/remove/reorder);
/// value-only changes never rebuild it (items handle those via [EntityScope]).
extension StoreRead<K, E extends Identifiable<K>> on StoreMemory<K, E, Msg> {
  List<K> of(BuildContext context) => _StoreHostState.read(context, this);
}

/// Hosted by the delegate above the navigators: the self-populating registry
/// backing [StoreRead.of] — a store is subscribed on its first read.
final class StoreHost extends StatefulWidget {
  const StoreHost({super.key, required this.child});

  final Widget child;

  @override
  State<StoreHost> createState() => _StoreHostState();
}

final class _StoreHostState extends State<StoreHost> {
  final Map<Object, _StoreWatch> _watches = {};
  final Map<Object, int> _versions = {};

  static List<K> read<K, E extends Identifiable<K>>(
      BuildContext context, StoreMemory<K, E, Msg> store) {
    final host = context.findAncestorStateOfType<_StoreHostState>();
    assert(host != null,
        'no StoreHost above this context — is the app under canon\'s delegate?');
    final ids = host!._watch(store);
    InheritedModel.inheritFrom<_StoreModel>(context, aspect: store);
    return ids.cast<K>();
  }

  List<Object?> _watch<K, E extends Identifiable<K>>(
      StoreMemory<K, E, Msg> store) {
    final w = _watches[store] ??= () {
      _versions[store] = 0;
      var ids = <Object?>[...store.entities.keys];
      late final _StoreWatch watch;
      final sub = store.changes.listen((_) {
        final next = <Object?>[...store.entities.keys];
        if (listEquals(next, watch.ids)) return;
        watch.ids = next;
        setState(() => _versions[store] = _versions[store]! + 1);
      });
      return watch = _StoreWatch(ids, sub);
    }();
    return w.ids;
  }

  @override
  void dispose() {
    for (final w in _watches.values) {
      w.sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _StoreModel(versions: {..._versions}, child: widget.child);
}

final class _StoreWatch {
  _StoreWatch(this.ids, this.sub);
  List<Object?> ids;
  final StreamSubscription<Object?> sub;
}

final class _StoreModel extends InheritedModel<Object> {
  const _StoreModel({required this.versions, required super.child});

  final Map<Object, int> versions;

  @override
  bool updateShouldNotify(_StoreModel old) => versions != old.versions;

  @override
  bool updateShouldNotifyDependent(_StoreModel old, Set<Object> aspects) =>
      aspects.any((s) => versions[s] != old.versions[s]);
}

final class _EntityEntry extends InheritedWidget {
  const _EntityEntry(
      {required this.entity,
      required this.id,
      required this.store,
      required super.child});

  final Object entity;
  final Object? id;
  final Object store;

  @override
  bool updateShouldNotify(_EntityEntry old) => !identical(entity, old.entity);
}
