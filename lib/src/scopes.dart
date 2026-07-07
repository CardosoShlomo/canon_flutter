import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:canon/canon.dart';

/// The spec-enum contract: a screen family carrying the grammar AND a `Widget`.
/// Binds the engine's abstract widget slot to Flutter's `Widget`, so consumers
/// write the clean form and `Widget get widget` is required:
///   `enum _Screens with ScreenNode<_Screens> { ... final Widget widget; }`
typedef ScreenNode<S extends ScreenNodeBase<S, Widget>>
    = ScreenNodeBase<S, Widget>;

/// A sub-enum's contract: like [ScreenNode] but the widget is OPTIONAL, so a row
/// can be a bare ref to an owner screen of the same name (the owner carries the
/// widget). Sub-enums mix this in; the trunk keeps [ScreenNode] (widget required),
/// so the trunk can never be a ref.
typedef SubScreenNode<S extends ScreenNodeBase<S, Widget?>>
    = ScreenNodeBase<S, Widget?>;

/// The page's grammar identity and transition policy inputs.
final class PageCtx {
  const PageCtx(this.screen, {this.animate = true, this.from});

  /// The screen this page renders. Ids are read inside the screen via the
  /// generated `context.idOf(...)`, not here — pageOf never sees a raw id.
  final Enum screen;

  /// False for pages that materialized mid-chain — suppresses their transition.
  final bool animate;

  /// Top screen when this page was pushed.
  final Enum? from;
}

/// Scopes a page's screen and id to its subtree, and gates its content: while
/// the tab is active everything renders; once parked, only screens that are
/// kept-when-parked (`keep`/`forget`) keep their real content — the rest
/// collapse to a `SizedBox` (freed, rebuilt fresh on return). With no liveness
/// in scope it always renders, so consumers not using it just keep all alive.
/// Internal: canon wraps each page in this (see `_buildPage`). Consumers never
/// construct it — they read their screen via the generated `context.idOf`/
/// `context.screen`, which route through the statics here.
@internal
final class ScreenScope extends StatelessWidget {
  const ScreenScope({super.key, required this.entry, required this.child});

  final StackEntry entry;
  final Widget child;

  /// The screen this context is under. Carries no id — read ids only via the
  /// typed [idOf], so a raw `Object?` id is never exposed to screen code.
  static Enum of(BuildContext context) => _entryOf(context).screen;

  static StackEntry _entryOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_ScreenEntry>();
    assert(scope != null, 'no ScreenScope above this context');
    return scope!.entry;
  }

  /// The typed id of screen [spec] this context is under. The single sanctioned
  /// id read; an id-bearing screen always has its id, so [T] is non-null.
  static T idOf<T>(BuildContext context, Enum spec) {
    final entry = _entryOf(context);
    assert(identical(entry.screen, spec),
        'idOf(${spec.name}) read under ${entry.screen.name}');
    return entry.id as T;
  }

  @override
  Widget build(BuildContext context) {
    final live = ScopeLiveness.of(context);
    final show = live == null || live.active || live.kept(entry.screen);
    return _ScreenEntry(
      entry: entry,
      child: show ? child : const SizedBox.shrink(),
    );
  }
}

/// Carries the page's grammar entry to descendants (the `of` lookup).
final class _ScreenEntry extends InheritedWidget {
  const _ScreenEntry({required this.entry, required super.child});

  final StackEntry entry;

  @override
  bool updateShouldNotify(_ScreenEntry oldWidget) => false;
}

/// Per-scope liveness the delegate provides: whether this tab is active, and
/// which of its screens stay live while parked. A flip of [active] re-gates the
/// scope's `ScreenScope`s.
final class ScopeLiveness extends InheritedWidget {
  const ScopeLiveness(
      {required this.active, required this.kept, required super.child});

  final bool active;
  final bool Function(Enum) kept;

  static ScopeLiveness? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ScopeLiveness>();

  @override
  bool updateShouldNotify(ScopeLiveness oldWidget) => active != oldWidget.active;
}

/// Reactive view-state. Widgets depend on a single key aspect (`q:screen.key` /
/// `f:screen.key`) and rebuild ONLY when that key is added, removed, or changed —
/// not on unrelated view-state or navigation. Provided above the Navigators.
final class ViewModel extends InheritedModel<String> {
  const ViewModel(
      {required this.snapshot, this.fragmentPathOf, required super.child});

  final Map<String, Object?> snapshot;

  /// Live PATH-fragment reader (the graph's `fragmentPathOf`) — change
  /// detection rides the snapshot's encoded `fp:` string; the decoded
  /// positions are read through this at build time.
  final List<Object?>? Function(Enum screen)? fragmentPathOf;

  static Object? read(BuildContext context, String aspect) =>
      InheritedModel.inheritFrom<ViewModel>(context, aspect: aspect)
          ?.snapshot[aspect];

  // Subscribe to a (screen, key) across both URL parts (a key lives in exactly
  // one; the other aspect never fires) and return its live value.
  static Object? readKey(BuildContext context, Enum screen, String key) {
    final q = read(context, 'q:${screen.name}.$key');
    final f = read(context, 'f:${screen.name}.$key');
    return q ?? f;
  }

  @override
  bool updateShouldNotify(ViewModel old) => !mapEquals(snapshot, old.snapshot);

  @override
  bool updateShouldNotifyDependent(ViewModel old, Set<String> aspects) =>
      aspects.any((a) => snapshot[a] != old.snapshot[a]);
}

/// Reactive, screen-local QUERY view-state. `Query.of<String>(context,
/// FeedKeys.category)` returns the value for the screen this context is under AND
/// subscribes the widget to that one key — it rebuilds only when the key is added,
/// removed, or changed. The key comes from a [QueryKeyBase] enum.
abstract final class Query {
  static T? of<T>(BuildContext context, QueryKeyBase key) =>
      ViewModel.read(context, 'q:${ScreenScope.of(context).name}.${key.name}')
          as T?;
}

/// Like [Query], but for the URL FRAGMENT view-state axis.
abstract final class Fragment {
  static T? of<T>(BuildContext context, QueryKeyBase key) =>
      ViewModel.read(context, 'f:${ScreenScope.of(context).name}.${key.name}')
          as T?;
}

/// Reactive PATH-scheme fragment (`#<seg>/<seg>`) of the screen this context
/// is under: the decoded positions in order, or null when unset. Subscribes
/// to the one path value — rebuilds only when it changes. Typed sugar over
/// the positions is the generator's job; position 0 of a list screen is its
/// item anchor.
abstract final class FragmentPath {
  static List<Object?>? of(BuildContext context) {
    final screen = ScreenScope.of(context);
    // Subscribe on the encoded-string aspect (stable value compare); read
    // the decoded positions through the model's live reader.
    final model =
        InheritedModel.inheritFrom<ViewModel>(context, aspect: 'fp:${screen.name}');
    return model?.fragmentPathOf?.call(screen);
  }
}

/// Aspect wrapper so `isCurrent` (top==screen) and `isOn` (chain∋screen) can both
/// key on a screen without colliding in [PlacementModel.updateShouldNotifyDependent].
class _CurrentAspect {
  const _CurrentAspect(this.screen);
  final Enum screen;
  @override
  bool operator ==(Object o) => o is _CurrentAspect && o.screen == screen;
  @override
  int get hashCode => screen.hashCode;
}

final class PlacementModel extends InheritedModel<Object> {
  const PlacementModel(
      {required this.chain, required this.top, required super.child});

  final Set<Enum> chain;
  final Enum top;

  static bool isOn(BuildContext context, Enum screen) =>
      InheritedModel.inheritFrom<PlacementModel>(context, aspect: screen)
          ?.chain
          .contains(screen) ??
      false;

  static bool isCurrent(BuildContext context, Enum screen) =>
      InheritedModel.inheritFrom<PlacementModel>(context,
              aspect: _CurrentAspect(screen))
          ?.top ==
      screen;

  @override
  bool updateShouldNotify(PlacementModel old) =>
      top != old.top || !setEquals(chain, old.chain);

  @override
  bool updateShouldNotifyDependent(PlacementModel old, Set<Object> aspects) {
    for (final a in aspects) {
      if (a is _CurrentAspect) {
        if ((top == a.screen) != (old.top == a.screen)) return true;
      } else if (a is Enum) {
        if (chain.contains(a) != old.chain.contains(a)) return true;
      }
    }
    return false;
  }
}

/// Reactive placement queries. `Placement.isOn(context, V.feed)` → is that screen
/// anywhere on the active chain; `Placement.isCurrent(context, V.feed)` → is it the
/// foreground top. Each rebuilds the widget only when its own status flips. The
/// generated `Screen.of(context, …)` / `Screen.isCurrentOf` forward here.
abstract final class Placement {
  static bool isOn(BuildContext context, Enum screen) =>
      PlacementModel.isOn(context, screen);
  static bool isCurrent(BuildContext context, Enum screen) =>
      PlacementModel.isCurrent(context, screen);

  /// The current foreground screen, BROADLY reactive — the widget rebuilds on any
  /// placement change. Backs the generated `Screen.of(context)` switch-to-render.
  static Enum? current(BuildContext context) =>
      InheritedModel.inheritFrom<PlacementModel>(context)?.top;
}

/// Reactive evaluation of a selector's view-state conditions — subscribes the
/// widget to exactly the keys referenced (so it rebuilds when they change) and
/// returns whether they all hold. Backs the generated `context.on`/`context.current`.
abstract final class ViewMatch {
  static bool conds(BuildContext context, Enum screen, List<ViewCond> conds) {
    for (final c in conds) {
      if (!c.test(ViewModel.readKey(context, screen, c.key))) return false;
    }
    return true;
  }
}

