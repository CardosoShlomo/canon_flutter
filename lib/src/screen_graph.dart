import 'package:flutter/widgets.dart';

import 'package:canon/canon.dart';

import 'scopes.dart';

List<NavigatorObserver> _noObservers() => const [];

/// The face-bearing construction of the one graph: the same grammar as
/// [NavGraph], plus everything that means "render this" — typed here, in
/// the tier that can name the types. Pure consumers (servers, links-only
/// trees, headless tests) construct [NavGraph] directly.
final class ScreenGraph extends NavGraph {
  ScreenGraph(
    super.trunkScreens, {
    super.seedChain,
    this.root,
    this.chrome,
    this.pageOf,
    this.observers = _noObservers,
  }) : assert(!(root != null && seedChain != null),
            'pass at most one of `root:` (the boot widget) or `seedChain:`');

  /// The boot loading UI, shown for the [BootScreen.root] entry and on a
  /// bare floor; null when the graph is seeded from a chain instead.
  final Widget? root;

  /// Dresses a screen's widget with the app's per-page chrome (scaffold,
  /// nav bar, safe areas). The host wraps the ScreenScope AROUND the chrome,
  /// so chrome reads `context.screen` like any screen content. Null → none.
  final Widget Function(Widget content, PageCtx ctx)? chrome;

  /// Builds a page for a screen's widget. Receives content already
  /// ScreenScope-wrapped (chrome included) — pageOf is page/route mechanics
  /// only, never widget composition. Null → a platform Material page.
  final Page<void> Function(Widget content, PageCtx ctx, LocalKey key)? pageOf;

  /// Navigator observers factory — a fresh list per Navigator.
  final List<NavigatorObserver> Function() observers;
}
