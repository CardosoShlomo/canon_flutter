import 'package:flutter/widgets.dart';

import 'package:canon/canon.dart';
import 'package:meta/meta.dart';

import 'scopes.dart';

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
  // A lazily-mounting item can race that fact — the sliver materializes a
  // child for an id deleted since the list's build — so absence at mount is
  // survivable: the scope renders nothing until the owning list catches up.
  void _read() {
    final entity = widget.store[widget.id];
    if (entity != null) {
      _entity = entity;
      _has = true;
    }
  }

  bool _has = false;

  void _listen() => _sub = widget.store.changes
      .where((k) => k == widget.id)
      .listen((_) => setState(_read));

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mounted for an already-deleted id (the lazy-sliver race): nothing to
    // scope — the owning list drops this item on its next build.
    if (!_has) return const SizedBox.shrink();
    // The scope plants its id too: identity ambience (IdScope.of) works
    // under an EntityScope without a second wrapper. The node comes from
    // the store's tag (generated bind() knows the grammar association).
    return IdEntry(
        id: widget.id,
        node: IdScope.nodeOf(widget.store),
        parent: context.getInheritedWidgetOfExactType<IdEntry>(),
        child: _EntityEntry(
            entity: _entity,
            id: widget.id,
            store: widget.store,
            child: widget.child));
  }
}

/// Identity ambience without data: plants ONE id over an item subtree, so
/// id-only lists (reactors, comments — rows that aren't store entities) get
/// deictic navigation. `EntityScope` plants this too — [of] works under
/// either scope. Pass [node] to tag the identity (the generated faces
/// resolve by node, so a tagged plant can never answer another node's read).
final class IdScope extends StatelessWidget {
  IdScope(this.id, {Key? key, this.node, required this.child})
      : super(key: key ?? ValueKey(id));

  final Object? id;
  final Enum? node;
  final Widget child;

  /// The ambient id at the nearest entry MATCHING [node] (an untagged plant
  /// matches everything; [node] omitted = plain nearest). INTERNAL: [K] is
  /// unchecked at runtime (extension types erase) — consumers read through
  /// the generated `<Node>ID.of(context)` faces, which supply the node.
  @internal
  static K of<K>(BuildContext context, [Enum? node]) =>
      _ambientId(context, node) as K;

  /// The deictic navigation handle at the ambient id — the generated verbs
  /// hang on it. INTERNAL: consumers mint via `<Node>ID.navOf(context)`.
  @internal
  static IdNav<K> navOf<K>(BuildContext context, [Enum? node]) =>
      IdNav(_ambientId(context, node) as K, ScreenScope.of(context));

  /// The SCREEN's own id, never an item's. INTERNAL: consumers read via
  /// `<Node>ID.screenOf(context)`.
  @internal
  static K screenOf<K>(BuildContext context) =>
      ScreenScope.ownIdOf<K>(context);

  /// The enclosing ITEM's id, never the screen's. INTERNAL: consumers read
  /// via `<Node>ID.itemOf(context)`.
  @internal
  static K itemOf<K>(BuildContext context) => EntityScope.idOf<K>(context);

  /// Tags a store with its grammar id node — emitted by the generated
  /// `bind()`, read back by every scope the store plants.
  @internal
  static void tag(Object store, Enum node) => _storeNodes[store] = node;

  /// The tagged node of [store], if the generated wiring declared one.
  @internal
  static Enum? nodeOf(Object store) => _storeNodes[store];

  static final _storeNodes = <Object, Enum>{};

  @override
  Widget build(BuildContext context) => IdEntry(
      id: id,
      node: node,
      parent: context.getInheritedWidgetOfExactType<IdEntry>(),
      child: child);
}

/// The nearest entry matching [node] — walks the plant chain; an untagged
/// entry is a wildcard. With [node] null, plain nearest.
Object? _ambientId(BuildContext context, [Enum? node]) {
  var e = context.getInheritedWidgetOfExactType<IdEntry>();
  if (node != null) {
    while (e != null && e.node != null && e.node != node) {
      e = e.parent;
    }
  }
  assert(e != null,
      'no ambient ${node == null ? 'id' : '`${node.name}` id'} above this context');
  return e!.id;
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
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(StoreBuilder<K, E> old) {
    super.didUpdateWidget(old);
    if (old.store != widget.store) {
      _sub?.cancel();
      _listen();
    }
  }

  // The engine decides structurally (its `structure` feed) — no diffing here.
  void _listen() =>
      _sub = widget.store.structure.listen((_) => setState(() {}));

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, [...widget.store.entities.keys]);
}

/// The two reactive collection reads, no builder. A store is many, so the
/// read must answer "of what?": [idsOf] for the key sequence, [entitiesOf]
/// for the rows themselves.
extension StoreRead<K, E extends Identifiable<K>> on StoreMemory<K, E, Msg> {
  /// The key SEQUENCE, reactively — rebuilds on add/remove/reorder only
  /// (the engine's `structure` feed); value changes NEVER fire here, so the
  /// consumer must scope each row with [item] / [entityOf] to see its data.
  List<K> idsOf(BuildContext context) => _StoreHostState.read(context, this);

  /// The ROWS, reactively — rebuilds on add/remove/reorder AND on ANY row's
  /// value change. The honest read for a widget that composes across rows
  /// (sums, filters, joins); costlier than [idsOf] by exactly that.
  List<E> entitiesOf(BuildContext context) =>
      _StoreHostState.readEntities(context, this);

  /// The keyed reactive read: the entity at [id], or — with [id] omitted —
  /// at the context's AMBIENT id, resolved at THIS store's own node (the
  /// generated tag): nearest matching plant, never another identity's.
  /// Rebuilds when THIS key appears, changes, or disappears. Nullable: the
  /// id may not be in this store (yet).
  E? entityOf(BuildContext context, [K? id]) => _StoreHostState.readKey(
      context, this, id ?? _ambientId(context, IdScope.nodeOf(this)) as K);

  /// Plants this store's item scope — the itemBuilder spelling of
  /// `EntityScope(store, id, child: …)`:
  ///
  /// ```dart
  /// itemBuilder: (_, i) => productsStore.item(ids[i], child: const _Tile()),
  /// ```
  Widget item(K id, {required Widget child}) =>
      EntityScope(this, id, child: child);

  /// The enclosing [EntityScope]'s id, ONLY if that scope was planted from
  /// THIS store — identity with provenance. Null when the nearest entity
  /// scope came from another source, so a shared item widget branches on
  /// where it stands: `chatsStore.idOf(context) ?? loopChat path`.
  K? idOf(BuildContext context) {
    final entry = context.getInheritedWidgetOfExactType<_EntityEntry>();
    assert(entry != null, 'no EntityScope above this context');
    return identical(entry!.store, this) ? entry.id as K : null;
  }
}

/// The reactive UNIT read: `viewerStore.of(context)` — the value, rebuilding
/// on every change of this one unit. Loading is an honest ledger row (an
/// in-flight unit) — read it with this same surface.
extension UnitRead<S, M extends Msg> on UnitMemory<S, M> {
  S of(BuildContext context) => _StoreHostState.readUnit(context, this);
}

/// The identity read on an entity-holding unit: the state's OWN id,
/// rebuilding ONLY when the identity changes — the unit's other fields churn
/// (counts, flags) without waking readers of who-is-here.
extension UnitIdRead<K, M extends Msg> on UnitMemory<Identifiable<K>?, M> {
  K? idOf(BuildContext context) => _StoreHostState.readUnitId(context, this);
}

/// Membership of the context's ambient id in a SET unit — the in-flight
/// idiom: `reviewsInFlightStore.containsIdOf(context)`. The set's ELEMENT
/// type states which identity the unit is keyed by; the id resolves like
/// [IdScope.of] (nearest planted scope, else the screen's own).
extension UnitSetRead<K, M extends Msg> on UnitMemory<Set<K>, M> {
  bool containsIdOf(BuildContext context) =>
      _StoreHostState.readUnit(context, this).contains(_ambientId(context));
}

/// Hosted by the delegate above the navigators: the self-populating registry
/// backing [StoreRead.idsOf] — a store is subscribed on its first read.
final class StoreHost extends StatefulWidget {
  const StoreHost({super.key, required this.child});

  final Widget child;

  @override
  State<StoreHost> createState() => _StoreHostState();
}

final class _StoreHostState extends State<StoreHost> {
  final Map<Object, _StoreWatch> _watches = {};
  final Map<Object, StreamSubscription<Object?>> _keyWatches = {};
  final Map<Object, int> _versions = {};
  final Map<Object, Object?> _lastIds = {};

  static List<K> read<K, E extends Identifiable<K>>(
      BuildContext context, StoreMemory<K, E, Msg> store) {
    final host = context.findAncestorStateOfType<_StoreHostState>();
    assert(host != null,
        'no StoreHost above this context — is the app under canon\'s delegate?');
    final ids = host!._watch(store);
    InheritedModel.inheritFrom<_StoreModel>(context, aspect: store);
    return ids.cast<K>();
  }

  static List<E> readEntities<K, E extends Identifiable<K>>(
      BuildContext context, StoreMemory<K, E, Msg> store) {
    final host = context.findAncestorStateOfType<_StoreHostState>();
    assert(host != null,
        'no StoreHost above this context — is the app under canon\'s delegate?');
    host!._watch(store);
    host._watchAnyKey(store);
    InheritedModel.inheritFrom<_StoreModel>(context, aspect: store);
    InheritedModel.inheritFrom<_StoreModel>(context, aspect: (store, #any));
    return [...store.entities.values];
  }

  /// One aspect for EVERY value change in [store] — what separates
  /// [StoreRead.entitiesOf] from the structure-only [StoreRead.idsOf].
  void _watchAnyKey<K, E extends Identifiable<K>>(
      StoreMemory<K, E, Msg> store) {
    final aspect = (store, #any);
    _keyWatches[aspect] ??= store.changes.listen((_) {
      setState(() => _versions[aspect] = (_versions[aspect] ?? 0) + 1);
    });
  }

  static E? readKey<K, E extends Identifiable<K>>(
      BuildContext context, StoreMemory<K, E, Msg> store, K id) {
    final host = context.findAncestorStateOfType<_StoreHostState>();
    assert(host != null,
        'no StoreHost above this context — is the app under canon\'s delegate?');
    host!._watchKeys(store);
    InheritedModel.inheritFrom<_StoreModel>(context, aspect: (store, id));
    return store[id];
  }

  /// Per-KEY subscription for [readKey] dependents: each changed key bumps its
  /// own (store, key) aspect — the engine's `changes` feed already names it.
  void _watchKeys<K, E extends Identifiable<K>>(StoreMemory<K, E, Msg> store) {
    _keyWatches[store] ??= store.changes.listen((k) {
      setState(() => _versions[(store, k)] = (_versions[(store, k)] ?? 0) + 1);
    });
  }

  static S readUnit<S, M extends Msg>(
      BuildContext context, UnitMemory<S, M> memory) {
    final host = context.findAncestorStateOfType<_StoreHostState>();
    assert(host != null,
        'no StoreHost above this context — is the app under canon\'s delegate?');
    host!._keyWatches[memory] ??= memory.changes.listen((_) {
      host.setState(
          () => host._versions[memory] = (host._versions[memory] ?? 0) + 1);
    });
    InheritedModel.inheritFrom<_StoreModel>(context, aspect: memory);
    return memory.state;
  }

  /// Per-IDENTITY subscription: the aspect `(memory, #id)` bumps only when
  /// the state's id changes, so id readers sleep through field churn.
  static K? readUnitId<K, M extends Msg>(
      BuildContext context, UnitMemory<Identifiable<K>?, M> memory) {
    final host = context.findAncestorStateOfType<_StoreHostState>();
    assert(host != null,
        'no StoreHost above this context — is the app under canon\'s delegate?');
    final aspect = (memory, #id);
    if (!host!._keyWatches.containsKey(aspect)) {
      host._lastIds[memory] = memory.state?.id;
      host._keyWatches[aspect] = memory.changes.listen((_) {
        final id = memory.state?.id;
        if (id == host._lastIds[memory]) return;
        host._lastIds[memory] = id;
        host.setState(
            () => host._versions[aspect] = (host._versions[aspect] ?? 0) + 1);
      });
    }
    InheritedModel.inheritFrom<_StoreModel>(context, aspect: aspect);
    return memory.state?.id;
  }

  List<Object?> _watch<K, E extends Identifiable<K>>(
      StoreMemory<K, E, Msg> store) {
    // The engine decides structurally (its `structure` feed) — no diffing here.
    final w = _watches[store] ??= () {
      _versions[store] = 0;
      final sub = store.structure.listen((_) {
        _watches[store]!.ids = <Object?>[...store.entities.keys];
        setState(() => _versions[store] = _versions[store]! + 1);
      });
      return _StoreWatch(<Object?>[...store.entities.keys], sub);
    }();
    return w.ids;
  }

  @override
  void dispose() {
    for (final w in _watches.values) {
      w.sub.cancel();
    }
    for (final s in _keyWatches.values) {
      s.cancel();
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
