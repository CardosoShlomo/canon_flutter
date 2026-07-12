// This file IS the host the engine's @internal surface exists for.
// ignore_for_file: invalid_use_of_internal_member

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show MaterialPage;
import 'package:flutter/widgets.dart';

import 'package:canon/canon.dart';

import 'entity_scope.dart';
import 'history_engine.dart'
    if (dart.library.js_interop) 'history_engine_web.dart';
import 'scopes.dart';
import 'screen_graph.dart';

/// Per-scope Flutter identity, hung off the engine's [NavScope] objects.
final _navKeys = Expando<GlobalKey<NavigatorState>>();
final _heroes = Expando<HeroController>();

GlobalKey<NavigatorState> _navKeyOf(NavScope scope) =>
    _navKeys[scope] ??= GlobalKey<NavigatorState>();

HeroController _heroOf(NavScope scope) => _heroes[scope] ??= HeroController();

/// Default page when the consumer gives no `pageOf`: a platform Material page.
Page<void> _defaultPageOf(Widget widget, PageCtx ctx, LocalKey key) =>
    MaterialPage<void>(key: key, child: widget);

final _delegates = Expando<NavDelegate>();

extension ScreenGraphFlutter on ScreenGraph {
  /// THE flutter host for this graph — created (and attached) on first read:
  /// `MaterialApp.router(routerDelegate: graph.delegate)`.
  NavDelegate get delegate => _delegates[this] ??= NavDelegate(this);
}

/// The flutter host: implements the engine's [NavHost] hooks, builds and
/// caches pages lazily per slot, and renders the visited scopes.
final class NavDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object>
    implements NavHost {
  NavDelegate(this._graph) {
    _graph.attachHost(this);
    if (_graph.ownsHistory) {
      // Flutter-engine settings for canon-owned web history: clean path URLs +
      // multi-entry mode (re-pinned post-frame — a Navigator init during the
      // first frame can re-assert single-entry).
      usePathUrls();
      enableMultiEntryHistory();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => enableMultiEntryHistory());
    }
  }

  final ScreenGraph _graph;

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navKeyOf(_graph.activeScope);

  @override
  void notify() => notifyListeners();

  @override
  void refresh() {
    _graph.writeHistory();
    notifyListeners();
  }

  @override
  void completeRebuild() => _graph.completeHistoryRebuild();

  Page<void> _pageFor(NavSlot slot) => (slot.page ??= _buildPage(slot)) as Page<void>;

  Page<void> _buildPage(NavSlot slot) {
    final entry = slot.entry;
    final screen = entry.screen;
    final ctx = PageCtx(screen, animate: slot.animate, from: slot.from);
    // canon owns the ScreenScope wrap — around the consumer's chrome too, so
    // chrome reads `context.screen` and the raw entry/id never reaches pageOf.
    // The boot entry's face is the graph's own `root`, never a row widget.
    final raw = screen == BootScreen.root
        ? _graph.root!
        : _graph.widgetOf(entry) as Widget;
    final dressed = _graph.chrome?.call(raw, ctx) ?? raw;
    final content = ScreenScope(entry: entry, child: dressed);
    final build = _graph.pageOf ?? _defaultPageOf;
    return build(
      content,
      ctx,
      screen == BootScreen.root
          ? const ValueKey('__boot__')
          : _graph.isMulti(screen)
              ? UniqueKey()
              : ValueKey(screen.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    // On a bare floor (a bounce that found nothing behind), the live stack is
    // stale — show the consumer's root widget, which reads `Screen.root.kind`.
    if (_graph.rootKind != null) return _graph.root!;
    final visited = _graph.visitedTrunks;
    return StoreHost(
      child: ViewModel(
        snapshot: _graph.viewSnapshot(),
        fragmentPathOf: _graph.fragmentPathOf,
        child: PlacementModel(
          chain: _graph.currentChain.toSet(),
          top: _graph.current,
          child: _buildStack(visited),
        ),
      ),
    );
  }

  Widget _buildStack(List<Enum> visited) {
    return IndexedStack(
      index: visited.indexOf(_graph.activeTrunk),
      children: [
        for (final trunk in visited)
          ScopeLiveness(
            active: trunk == _graph.activeTrunk,
            kept: _graph.spec.keptWhenParked,
            child: TickerMode(
              enabled: trunk == _graph.activeTrunk,
              child: HeroControllerScope(
                controller: _heroOf(_graph.scopeFor(trunk)!),
                child: Navigator(
                  key: _navKeyOf(_graph.scopeFor(trunk)!),
                  observers: _graph.observers(),
                  pages: [
                    for (final s in _graph.scopeFor(trunk)!.slots) _pageFor(s),
                  ],
                  onDidRemovePage: _graph.onPageRemoved,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Null: canon drives the browser History API directly, so the framework
  /// must not auto-report. Input arrives via canon's own popstate listener.
  @override
  RouteInformation? get currentConfiguration => null;

  /// Cold-load / back / forward / refresh / deep-link land here; the engine
  /// decides blob-restore vs resolver vs nav-mirror reconcile.
  @override
  Future<void> setNewRoutePath(Object configuration) {
    if (configuration is RouteInformation) {
      _graph.routeFromBrowser(
          configuration.uri.toString(), configuration.state);
    }
    return SynchronousFuture(null);
  }
}

/// Parses incoming browser [RouteInformation] for the Router. Pass-through: the
/// blob/URL split is decided in [NavDelegate.setNewRoutePath].
final class CanonRouteParser extends RouteInformationParser<Object> {
  const CanonRouteParser();

  @override
  Future<Object> parseRouteInformation(RouteInformation information) =>
      SynchronousFuture(information);

  @override
  RouteInformation? restoreRouteInformation(Object configuration) =>
      configuration is RouteInformation ? configuration : null;
}

/// Drop into `MaterialApp(home: ScreenManager(graph))`. Hosts the same nav
/// tree as the delegate but with no Router/RouteInformation channel, so URLs
/// and deep-links can't drive the stack — handle links imperatively. Owns
/// system back; persists/restores the snapshot under [restorationId].
final class ScreenManager extends StatelessWidget {
  ScreenManager(this.graph, {super.key, this.restorationId = 'nav'})
      : delegate = NavDelegate(graph);

  final ScreenGraph graph;
  final String restorationId;
  final NavDelegate delegate;

  @override
  Widget build(BuildContext context) => RootRestorationScope(
        restorationId: restorationId,
        child: _ManagerBody(graph, delegate),
      );
}

class _ManagerBody extends StatefulWidget {
  const _ManagerBody(this.graph, this.delegate);

  final NavGraph graph;
  final NavDelegate delegate;

  @override
  State<_ManagerBody> createState() => _ManagerBodyState();
}

class _ManagerBodyState extends State<_ManagerBody>
    with RestorationMixin, WidgetsBindingObserver {
  final RestorableStringN _snap = RestorableStringN(null);
  VoidCallback? _off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // Routes system back to the active scope's navigator (no Router needed).
  @override
  Future<bool> didPopRoute() => widget.delegate.popRoute();

  @override
  String? get restorationId => 'canon_nav';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_snap, 'stack');
    final s = _snap.value;
    if (s != null) {
      widget.graph.restore(jsonDecode(s) as Map<String, Object?>);
    }
    _off ??= widget.graph
        .observe((_, _) => _snap.value = jsonEncode(widget.graph.toState()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _off?.call();
    _snap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.delegate;
    return AnimatedBuilder(
      animation: d,
      builder: (context, _) => d.build(context),
    );
  }
}
