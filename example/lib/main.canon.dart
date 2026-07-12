// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'main.dart';

// **************************************************************************
// CanonGenerator
// **************************************************************************

// Typed ids — nominal identity in the value space, generated
// from the @ids grammar. Zero-cost: each erases to its codec's
// value type at runtime. `node` links back to the grammar
// (`XId.node.codec` reaches the codec).
extension type const ProductId(String _) implements String {
  static const Ids node = Ids.product;
}

// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: invalid_use_of_internal_member
bool _chainIs(List<Enum> a, List<Enum> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

final class Screen<I> {
  const Screen._(this._spec);
  final Enum _spec;

  /// This screen's name, as written in the grammar enum — the
  /// readable identity of a stack entry (`Screen.stack.current.name`).
  String get name => _spec.name;
  static const catalog = Screen<Never>._(_Screens.catalog);
  static const product = Screen<ProductId>._(_Screens.product);
  static const orders = Screen<Never>._(_Screens.orders);
  static const about = Screen<Never>._(_Screens.about);
  static Screen<Object?> _forSpec(Enum spec) => _bySpec[spec]!;

  /// The [Screen] constant for a grammar row — `pageOf`'s bridge from
  /// `PageCtx.screen` to the typed surface (per-screen meta extensions
  /// switch on the constants).
  static Screen<Object?> from(Enum spec) => _bySpec[spec]!;

  /// The current foreground as a read-only view, reactively — switch
  /// it to render per screen. Null when the current screen has no
  /// view-state. (`Placement.isOn`/`Placement.isCurrent` for raw checks.)
  static AnyView? of(BuildContext context) =>
      _viewOf(Placement.current(context));

  /// Reactive: is the screen THIS context is under the current foreground
  /// top? Rebuilds only when that flips. The self-vs-current gate —
  /// `if (Screen.isCurrentOf(context)) …` to act only while visible.
  static bool isCurrentOf(BuildContext context) =>
      Placement.isCurrent(context, ScreenScope.of(context));
  static const _bySpec = <Enum, Screen<Object?>>{
    BootScreen.root: Screen<Never>._(BootScreen.root),
    _Screens.catalog: catalog,
    _Screens.product: product,
    _Screens.orders: orders,
    _Screens.about: about,
  };

  /// The live active stack as wrappers: .current/.currentId/.tab/
  /// .screens/.reachable, extensible without touching Screen.
  static NavStack<Screen<Object?>> get stack => NavStack([
    for (final e in _Screens.graph.stack) NavEntry(_forSpec(e.screen), e.id),
  ]);

  /// The active top screen's QUERY view-state, read-only and
  /// context-free (the headless peer of `Query.of(context, ...)`).
  static Map<String, Object?> get query => _Screens.graph.activeView('q');

  /// The active top screen's FRAGMENT view-state, read-only and
  /// context-free.
  static Map<String, Object?> get fragment => _Screens.graph.activeView('f');
  static const _treeSignature = 'about();catalogK(product());orders()';

  /// True when this generated code still matches the live tree.
  /// Assert it in a test to fail CI on a stale (un-regenerated) tree:
  /// `test('nav codegen fresh', () => expect(Screen.isCodegenFresh, true));`
  static bool get isCodegenFresh =>
      _Screens.graph.structureSignature == _treeSignature;
  static final bool _fresh = () {
    assert(
      isCodegenFresh,
      'canon: the navigation tree changed but generated code is stale — run build_runner.',
    );
    return true;
  }();

  /// THE app host — a `RouterDelegate`. Wire it once:
  /// `MaterialApp.router(routerDelegate: Screen.manager)`. It owns the
  /// in-memory stack, drives browser back/forward + the URL channel on
  /// web, and system back on mobile. (The placement may change; the name
  /// stays — always pass it where a `RouterDelegate` goes.)
  static NavDelegate get manager {
    assert(_fresh);
    return _Screens.graph.delegate;
  }

  /// A restoration-serializable snapshot of the whole nav state
  /// (no URLs; ids via each screen codec). Persist + [restore] it.
  static Map<String, Object?> snapshot() => _Screens.graph.toState();

  /// Rebuilds the stack from a [snapshot], best-effort. Returns
  /// false on a stale/incompatible snapshot.
  static bool restore(Map<String, Object?> state) =>
      _Screens.graph.restore(state);

  /// Executes a resolved [Hop] — the path a parsed [Place] carries.
  /// This is how a resolver commits an inbound link:
  /// `Screen.resolver = (url) { if (url case Place p) Screen.go(p); };`.
  static N go<N extends AnyNav>(Hop<N> hop) {
    for (final (s, i) in hop.chain) _Screens.graph.go<Object?>(s, i);
    return hop.nav;
  }

  /// If the live stack ends with this selector path (every pinned id and,
  /// for a cyclic terminal, its depth matching), its nav — else null.
  static N? on<N extends AnyNav, V>(On<N, V> which) {
    final st = _Screens.graph.stack;
    final specs = which.specs;
    if (specs.isEmpty) {
      for (final c in which.conds) {
        if (!c.test(_Screens.graph.viewGet(_Screens.graph.current, c.key)))
          return null;
      }
      return _atOf(_Screens.graph.current) as N;
    }
    if (st.length < specs.length) return null;
    final off = st.length - specs.length;
    for (var i = 0; i < specs.length; i++) {
      if (st[off + i].screen != specs[i]) return null;
      final wid = which.ids[i];
      if (wid != null && st[off + i].id != wid) return null;
    }
    for (final c in which.conds) {
      if (!c.test(_Screens.graph.viewGet(specs.last, c.key))) return null;
    }
    return _atOf(specs.last) as N;
  }

  /// The placement if this selector path is anywhere on the live stack
  /// (front OR buried) — for `Screen.at(.x)?.surface()`. Else null.
  static N? at<N extends AnyNav, V>(On<N, V> which) {
    final st = _Screens.graph.stack;
    final specs = which.specs;
    if (specs.isEmpty) {
      for (final entry in st) {
        if (which.conds.every(
          (c) => c.test(_Screens.graph.viewGet(entry.screen, c.key)),
        )) {
          return _atOf(entry.screen) as N;
        }
      }
      return null;
    }
    outer:
    for (var e = st.length - 1; e >= specs.length - 1; e--) {
      final off = e - specs.length + 1;
      for (var i = 0; i < specs.length; i++) {
        if (st[off + i].screen != specs[i]) continue outer;
        final wid = which.ids[i];
        if (wid != null && st[off + i].id != wid) continue outer;
      }
      for (final c in which.conds) {
        if (!c.test(_Screens.graph.viewGet(specs.last, c.key))) continue outer;
      }
      return _atOf(specs.last) as N;
    }
    return null;
  }

  /// The placement OWNING [context] (this widget's screen), reactive.
  static AnyPlacement ownerOf(BuildContext context) {
    Placement.isOn(context, ScreenScope.of(context));
    return _atOf(ScreenScope.of(context));
  }

  /// Is the screen owning [context] the current foreground? Reactive.
  static bool isForegroundOf(BuildContext context) =>
      Placement.isCurrent(context, ScreenScope.of(context));

  /// The read-only view of the screen owning [context] (or null if it
  /// has no view-state) — `switch` it for the typed view. Reactive.
  static AnyView? viewOf(BuildContext context) {
    Placement.isOn(context, ScreenScope.of(context));
    return _viewOf(ScreenScope.of(context));
  }

  /// Live-stack redirect: the chained verb REPLACES the current history
  /// entry instead of pushing. Decide it at the start —
  /// `Screen.replace.goHome()`, `Screen.replace.on(.user)?.goChat(id)`.
  static const replace = Replace._();

  /// The root (history bottom) controls: `Screen.root.anchor()` keeps the
  /// launch position returnable; `Screen.root.passthrough()` makes it a
  /// throwaway that exits on back.
  static const root = RootControls._();

  /// The current foreground placement (the front), as the sealed
  /// [AnyPlacement] — `switch (Screen.current) { … }` is exhaustive.
  static AnyPlacement get current => _atOf(_Screens.graph.current);

  /// The cold-start link, parsed from the launch URL — read it in the
  /// `root` boot UI to vary the loading screen by destination. Eager:
  /// available from the first build, independent of the Router callback.
  /// Null when the launch URL isn't a representable link.
  static Url? get rootUrl {
    final u =
        _Screens.graph.bootUrl ??
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    return parseUrl(u);
  }

  /// THE navigation resolver — assign once (ideally in `main` before
  /// `runApp`). Fires with the cold-start link (or null), then on every
  /// deep link — web URL + mobile app-link, one channel. Write plain
  /// `Screen.goX()` / `Screen.replace`. Single, last-wins, never disposed.
  static set resolver(void Function(Url? url) fn) => _Screens.graph.setResolver(
    (url) => fn(parseUrl(url)),
    boot:
        _Screens.graph.bootUrl ??
        WidgetsBinding.instance.platformDispatcher.defaultRouteName,
  );

  /// The poppable handle if the active top is a non-root placement,
  /// else null (at a scope root). `.at` = current placement; `.pop()`
  /// executes the guaranteed pop and returns the destination.
  static CanPopNav? get canPop =>
      _Screens.graph.currentChain.length > 1 ? const CanPopNav._() : null;

  /// Documented sugar for `canPop?.pop()` — pops the active top if any,
  /// returns where it landed, or null at a root. Never throws.
  static PopDestPlacement? pop() => canPop?.pop();

  /// A broadcast stream of committed navigations as typed snapshots:
  /// `from`/`to` are ScreenEntry stacks; `switch (e.destination)` for
  /// the landed screen + its typed id. Filter with `.where`.
  static Stream<ScreenNavigation> get navigations =>
      _Screens.graph.navigations.map(ScreenNavigation._);
  static void forgetCatalog() => _Screens.graph.forget(_Screens.catalog);
  static CatalogNav goCatalog() {
    _Screens.graph.go(_Screens.catalog);
    return const CatalogNav._();
  }

  static ProductNav goProduct(ProductId id) {
    _Screens.graph.go(_Screens.product, id);
    return const ProductNav._();
  }

  static OrdersNav goOrders() {
    _Screens.graph.go(_Screens.orders);
    return const OrdersNav._();
  }

  static AboutNav goAbout() {
    _Screens.graph.go(_Screens.about);
    return const AboutNav._();
  }
}

/// The `Screen.root` facade — controls for the root (the history bottom):
/// whether the launch position is a returnable root or a throwaway that
/// exits on back.
final class RootControls {
  const RootControls._();

  /// Persist the launch/root position as returnable — back returns to it
  /// (then exits), and trunk-switches stack above it.
  void anchor() => _Screens.graph.anchor();

  /// Make the launch/root a throwaway that exits on back (the default).
  void passthrough() => _Screens.graph.passthrough();

  /// On a BARE root the `root` widget renders — read this to branch
  /// (a `sentinel`/`fallthrough` kind), or null while boot-loading.
  FloorKind? get kind => _Screens.graph.rootKind;

  /// The current front screen's widget — `return Screen.root.front` from
  /// the `root` widget to keep showing it on a bare root.
  Widget? get front => _Screens.graph.frontWidget as Widget?;
}

/// The `Screen.replace` redirect facade — every verb mirrors `Screen`
/// but commits as a history REPLACE (web `replaceState`).
final class Replace {
  const Replace._();
  N go<N extends AnyNav>(Hop<N> hop) {
    _Screens.graph.markReplace();
    return Screen.go(hop);
  }

  /// Scoped redirect — replace is decided here, before scoping; a miss
  /// (null) commits nothing, so the pending flag is dropped, not leaked.
  N? on<N extends AnyNav, V>(On<N, V> which) {
    _Screens.graph.markReplace();
    return Screen.on(which);
  }

  /// Replace-mode reach: the placement anywhere on the stack, so the
  /// following `surface()` / `goX()` commits as a replace (or, on a miss,
  /// nothing — the flag drops, not leaks).
  N? at<N extends AnyNav, V>(On<N, V> which) {
    _Screens.graph.markReplace();
    return Screen.at(which);
  }

  CatalogNav goCatalog() {
    _Screens.graph.markReplace();
    return Screen.goCatalog();
  }

  ProductNav goProduct(ProductId id) {
    _Screens.graph.markReplace();
    return Screen.goProduct(id);
  }

  OrdersNav goOrders() {
    _Screens.graph.markReplace();
    return Screen.goOrders();
  }

  AboutNav goAbout() {
    _Screens.graph.markReplace();
    return Screen.goAbout();
  }
}

/// One committed navigation as typed [ScreenEntry] stacks.
final class ScreenNavigation {
  ScreenNavigation._(this._n);
  final Navigation _n;
  List<ScreenEntry> get from => [for (final e in _n.from) _entryOf(e.$1, e.$2)];
  List<ScreenEntry> get to => [for (final e in _n.to) _entryOf(e.$1, e.$2)];
  ScreenEntry get source => _entryOf(_n.source.$1, _n.source.$2);
  ScreenEntry get destination => _entryOf(_n.destination.$1, _n.destination.$2);
  NavDirection get direction => _n.direction;
  bool get isForward => _n.isForward;
  bool get isBackward => _n.isBackward;
  bool get isRoundTrip => _n.isRoundTrip;
  bool get isJump => _n.isJump;
}

/// One typed entry per screen — `switch` it for the screen-specific id.
sealed class ScreenEntry {
  const ScreenEntry();
}

final class CatalogEntry extends ScreenEntry {
  const CatalogEntry();
}

final class ProductEntry extends ScreenEntry {
  const ProductEntry(this.id);
  final ProductId id;
}

final class OrdersEntry extends ScreenEntry {
  const OrdersEntry();
}

final class AboutEntry extends ScreenEntry {
  const AboutEntry();
}

ScreenEntry _entryOf(Enum s, Object? id) => switch (s) {
  _Screens.catalog => const CatalogEntry(),
  _Screens.product => ProductEntry(id as ProductId),
  _Screens.orders => const OrdersEntry(),
  _Screens.about => const AboutEntry(),
  _ => throw StateError('not a _Screens screen'),
};

final class Hop<N extends AnyNav> {
  const Hop._(this.spec, this.id, this.nav);
  final Enum spec;
  final Object? id;
  final N nav;

  /// The root-down chain this hop replays. A single kick-start is one
  /// segment; a navigable `Place` (a `Place`) overrides it with its
  /// full path, so `Screen.go` lands the whole placement.
  List<(Enum, Object?)> get chain => [(spec, id)];

  /// The screen this hop lands on — the total projection
  /// (the inverse needs an id, so it stays a Hop ctor).
  Screen<Object?> get screen => Screen._forSpec(spec);
  static const catalog = Hop<CatalogNav>._(
    _Screens.catalog,
    null,
    CatalogNav._(),
  );
  static Hop<ProductNav> product(ProductId id) =>
      Hop._(_Screens.product, id, const ProductNav._());
  static const orders = Hop<OrdersNav>._(_Screens.orders, null, OrdersNav._());
  static const about = Hop<AboutNav>._(_Screens.about, null, AboutNav._());
}

/// The root/boot placement: `Screen.current` returns it until the first
/// commit. `if (Screen.current case Root()) ...` gates blob-null cold-boot UI.
final class Root extends AnyPlacement {
  const Root._() : super._();
}

final class On<N extends AnyNav, V> {
  const On._(this.specs, this.ids, this.nav, [this.conds = const []]);
  final List<Enum> specs;
  final List<Object?> ids;

  /// The exact nav for a single-placement terminal; null for a multi-
  /// placement one — `Screen.on` resolves it from the live chain.
  final N? nav;

  /// View-state conditions on the terminal screen (`.query`/`.fragment`).
  final List<ViewCond> conds;
  static OnCatalog get catalog =>
      OnCatalog._([_Screens.catalog], [null], const CatalogNav._());
  static OnProduct get product =>
      OnProduct._([_Screens.product], [null], const ProductNav._());
  static On<OrdersNav, AnyView> get orders =>
      On._([_Screens.orders], [null], const OrdersNav._());
  static On<AboutNav, AnyView> get about =>
      On._([_Screens.about], [null], const AboutNav._());

  /// GLOBAL query conditions, unbound to a screen — `context.on(.query(
  /// {…}))` (foreground) / `context.at(.query({…}))` (anywhere on stack).
  static On<AnyPlacement, AnyView> query(Set<QueryCond> cs) =>
      On._(const [], const [], null, [...cs]);
}

final class OnCatalog extends On<CatalogNav, CatalogView> {
  const OnCatalog._(super.specs, super.ids, super.nav, [super.conds])
    : super._();
  OnCatalog query(Set<CatalogQueryCond> cs) =>
      OnCatalog._(specs, ids, nav, [...conds, ...cs]);
  OnProduct get product => OnProduct._(
    [...specs, _Screens.product],
    [...ids, null],
    const ProductNav._(),
  );
}

final class OnProduct extends On<ProductNav, AnyView> {
  const OnProduct._(super.specs, super.ids, super.nav) : super._();
  OnProduct call(ProductId id) =>
      OnProduct._(specs, [...ids.sublist(0, ids.length - 1), id], nav);
}

sealed class AnyPlacement extends AnyNav {
  const AnyPlacement._() : super._();
}

AnyPlacement _atOf(Enum s) {
  return switch (s) {
    _Screens.catalog => const CatalogNav._(),
    _Screens.product => const ProductNav._(),
    _Screens.orders => const OrdersNav._(),
    _Screens.about => const AboutNav._(),
    BootScreen.root => const Root._(),
    _ => throw StateError('not a _Screens screen'),
  };
}

abstract base class AnyNav {
  const AnyNav._();
}

sealed class PopDestPlacement {}

final class CanPopNav extends AnyNav {
  const CanPopNav._() : super._();
  PopDestPlacement pop() {
    _Screens.graph.pop();
    return _resolvePopDest();
  }
}

PopDestPlacement _resolvePopDest() {
  final c = _Screens.graph.currentChain;
  if (_chainIs(c, const [_Screens.catalog])) return const CatalogNav._();
  throw StateError('unresolved pop destination: $c');
}

final class CatalogNav extends AnyPlacement
    implements CatalogView, PopDestPlacement {
  const CatalogNav._() : super._();
  CatalogNav surface() {
    _Screens.graph.popTo(_Screens.catalog);
    return const CatalogNav._();
  }

  CatalogQueryMut get query => const CatalogQueryMut._();
  ProductNav goProduct(ProductId id) {
    _Screens.graph.popTo(_Screens.catalog);
    _Screens.graph.go(_Screens.product, id, true);
    return const ProductNav._();
  }
}

final class ProductNav extends AnyPlacement {
  const ProductNav._() : super._();
  ProductNav surface() {
    _Screens.graph.popTo(_Screens.product);
    return const ProductNav._();
  }

  CatalogNav pop() {
    _Screens.graph.pop();
    return const CatalogNav._();
  }
}

final class OrdersNav extends AnyPlacement {
  const OrdersNav._() : super._();
  OrdersNav surface() {
    _Screens.graph.popTo(_Screens.orders);
    return const OrdersNav._();
  }
}

final class AboutNav extends AnyPlacement {
  const AboutNav._() : super._();
  AboutNav surface() {
    _Screens.graph.popTo(_Screens.about);
    return const AboutNav._();
  }
}

extension type const ScreenId<I>._(Enum spec) {
  static const product = ScreenId<ProductId>._(_Screens.product);
}

extension ScreenIdOf on BuildContext {
  I idOf<I>(ScreenId<I> screen) => ScreenScope.idOf<I>(this, screen.spec);

  /// The screen this widget belongs to (its enclosing scope).
  Screen<Object?> get screen => Screen._forSpec(ScreenScope.of(this));
}

void verifyScreens() {
  assert(() {
    assert(
      _Screens.catalog.id == null,
      'catalog has an unexpected id codec — rerun build_runner',
    );
    assert(
      _Screens.product.id != null,
      'product is missing its id codec — rerun build_runner',
    );
    assert(
      _Screens.orders.id == null,
      'orders has an unexpected id codec — rerun build_runner',
    );
    assert(
      _Screens.about.id == null,
      'about has an unexpected id codec — rerun build_runner',
    );
    return true;
  }());
}

/// A URL the app understands: a [Place] or a [Link]. Build one with
/// `Url.<route>…` and `.toUri([domain])`; `parseUrl` returns one.
sealed class Url {
  const Url([this.domain]);
  Uri toUri([String? domain]);

  /// The inbound origin (`scheme://host[:port]`) when this came from
  /// `parseUrl` (read it in `Screen.resolver`); null when built locally.
  final String? domain;
  static _WLCatalog get catalog => _WLCatalog._([_Screens.catalog], [null]);
  static _WLCatalogProduct product(ProductId id) =>
      _WLCatalogProduct._([_Screens.catalog, _Screens.product], [null, id]);
  static _WLOrders get orders => _WLOrders._([_Screens.orders], [null]);
  static _WLAbout get about => _WLAbout._([_Screens.about], [null]);
}

/// A POSITION in the tree — a screen with a widget to present and a nav
/// destination. Go-able: every `Place` is a [Hop], so `Screen.go(place)`
/// replays its root-down chain and lands the placement. Built root-down
/// (`Place.home.item(id)`); a parsed nav-mirror URL is one.
sealed class Place extends Url implements Hop<AnyNav> {
  const Place([super.domain]);
  @override
  List<(Enum, Object?)> get chain;
  @override
  Enum get spec => chain.last.$1;
  @override
  Object? get id => chain.last.$2;
  @override
  AnyNav get nav => _atOf(_Screens.graph.current);
  @override
  Screen<Object?> get screen => Screen._forSpec(spec);
  static _WLCatalog get catalog => _WLCatalog._([_Screens.catalog], [null]);
  static _WLCatalogProduct product(ProductId id) =>
      _WLCatalogProduct._([_Screens.catalog, _Screens.product], [null, id]);
  static _WLOrders get orders => _WLOrders._([_Screens.orders], [null]);
  static _WLAbout get about => _WLAbout._([_Screens.about], [null]);
}

/// A resolve-only branch (declared via `.link`/`slots`): URL-shaped DATA
/// the resolver interprets. NOT a position — no widget, never navigable.
/// Shareable via `Link.<route>.toUri()`; read its fields in `Screen.resolver`.
sealed class Link extends Url {
  const Link([super.domain]);
  static _LXProduct get product => _LXProduct(const <Object?>[], const <int>[]);
}

/// The bare root `/` — a plain app-open (no specific destination).
final class RootUrl extends Url {
  const RootUrl([super.domain]);
  @override
  Uri toUri([String? domain]) =>
      Uri.parse((domain ?? 'https://shop.example') + '/');
}

/// A nav-mirror `Place` parsed from a URL (e.g. `/home/item/42`); carries
/// the root-down chain so `Screen.go` lands it.
final class _NavPlace extends Place {
  const _NavPlace(this.chain, [super.domain]);
  @override
  final List<(Enum, Object?)> chain;
  @override
  Uri toUri([String? domain]) => Uri.parse(
    _Screens.graph.encodeNavUrl(
      domain ?? 'https://shop.example',
      [for (final c in chain) c.$1],
      [for (final c in chain) c.$2],
    ),
  );
}

final class ProductLink extends Link {
  const ProductLink(this.value0, [super.domain]);
  final Object value0;
  @override
  Uri toUri([String? domain]) => Uri.parse(
    _Screens.graph.encodeLink(
      domain ?? 'https://shop.example',
      'product/*',
      <Object?>[value0],
      <int>[0],
    ),
  );
}

/// Parses [url] into a [Url]: a declared [Link], a nav-mirror [Place]
/// (go-able), [RootUrl] for bare `/`, or null if it resolves to nothing.
/// The result carries the inbound origin in [Url.domain].
Url? parseUrl(String url) {
  final uri = Uri.parse(url);
  final origin = uri.hasAuthority ? '${uri.scheme}://${uri.authority}' : null;
  final m = _Screens.graph.parseLink(url);
  if (m != null) {
    final link = switch (m.template) {
      'product/*' => ProductLink(m.path[0] as Object, origin),
      _ => null,
    };
    if (link != null) return link;
  }
  // Bare root → a plain app-open.
  if (uri.pathSegments.where((s) => s.isNotEmpty).isEmpty) {
    return RootUrl(origin);
  }
  // Nav-mirror path → a go-able Place.
  final chain = _Screens.graph.parsePath(url);
  if (chain != null) return _NavPlace(chain, origin);
  return null;
}

class _LXProduct {
  _LXProduct(this._p, this._b);
  final List<Object?> _p;
  final List<int> _b;
  _LXProductSlot call(Object value0) =>
      _LXProductSlot([..._p, value0], [..._b, 0]);
}

class _LXProductSlot {
  _LXProductSlot(this._p, this._b);
  final List<Object?> _p;
  final List<int> _b;
  Uri toUri([String? domain]) => Uri.parse(
    _Screens.graph.encodeLink(
      domain ?? 'https://shop.example',
      'product/*',
      _p,
      _b,
    ),
  );
}

final class _WLCatalog implements Hop<CatalogNav> {
  const _WLCatalog._(this._s, this._i);
  final List<Enum> _s;
  final List<Object?> _i;
  @override
  List<(Enum, Object?)> get chain => [
    for (var k = 0; k < _s.length; k++) (_s[k], _i[k]),
  ];
  @override
  Enum get spec => _s.last;
  @override
  Object? get id => _i.last;
  @override
  CatalogNav get nav => const CatalogNav._();
  @override
  Screen<Object?> get screen => Screen._forSpec(spec);
  _WLCatalogProduct product(ProductId id) =>
      _WLCatalogProduct._([..._s, _Screens.product], [..._i, id]);
  _WLCatalogQ query(Set<CatalogQueryArg> q) =>
      _WLCatalogQ(_s, _i, {for (final t in q) t.key: t.value}, const {});
  Uri toUri([String? domain]) => Uri.parse(
    _Screens.graph.encodeNavUrl(domain ?? 'https://shop.example', _s, _i),
  );
}

class _WLCatalogQ {
  _WLCatalogQ(this._s, this._i, this._q, this._f);
  final List<Enum> _s;
  final List<Object?> _i;
  final Map<String, Object?> _q;
  final Map<String, Object?> _f;
  Uri toUri([String? domain]) => Uri.parse(
    _Screens.graph.encodeNavUrl(
      domain ?? 'https://shop.example',
      _s,
      _i,
      _q,
      _f,
    ),
  );
}

final class _WLCatalogProduct implements Hop<ProductNav> {
  const _WLCatalogProduct._(this._s, this._i);
  final List<Enum> _s;
  final List<Object?> _i;
  @override
  List<(Enum, Object?)> get chain => [
    for (var k = 0; k < _s.length; k++) (_s[k], _i[k]),
  ];
  @override
  Enum get spec => _s.last;
  @override
  Object? get id => _i.last;
  @override
  ProductNav get nav => const ProductNav._();
  @override
  Screen<Object?> get screen => Screen._forSpec(spec);
  Uri toUri([String? domain]) => Uri.parse(
    _Screens.graph.encodeNavUrl(domain ?? 'https://shop.example', _s, _i),
  );
}

final class _WLOrders implements Hop<OrdersNav> {
  const _WLOrders._(this._s, this._i);
  final List<Enum> _s;
  final List<Object?> _i;
  @override
  List<(Enum, Object?)> get chain => [
    for (var k = 0; k < _s.length; k++) (_s[k], _i[k]),
  ];
  @override
  Enum get spec => _s.last;
  @override
  Object? get id => _i.last;
  @override
  OrdersNav get nav => const OrdersNav._();
  @override
  Screen<Object?> get screen => Screen._forSpec(spec);
  Uri toUri([String? domain]) => Uri.parse(
    _Screens.graph.encodeNavUrl(domain ?? 'https://shop.example', _s, _i),
  );
}

final class _WLAbout implements Hop<AboutNav> {
  const _WLAbout._(this._s, this._i);
  final List<Enum> _s;
  final List<Object?> _i;
  @override
  List<(Enum, Object?)> get chain => [
    for (var k = 0; k < _s.length; k++) (_s[k], _i[k]),
  ];
  @override
  Enum get spec => _s.last;
  @override
  Object? get id => _i.last;
  @override
  AboutNav get nav => const AboutNav._();
  @override
  Screen<Object?> get screen => Screen._forSpec(spec);
  Uri toUri([String? domain]) => Uri.parse(
    _Screens.graph.encodeNavUrl(domain ?? 'https://shop.example', _s, _i),
  );
}

/// Read-only placement view — the reactive reads return these.
sealed class AnyView {}

/// GLOBAL query condition terms — `.key` present / `.key(v)` equals / `.flag` true; `.not.…` negates (`.not.key` = absent).
final class QueryCond<T> implements ViewCond {
  const QueryCond._(
    this.key,
    this.expected, {
    this.negate = false,
    this.presence = false,
  });
  @override
  final String key;
  final Object? expected;
  final bool negate;
  final bool presence;

  /// `.key(v)` — narrow a present term to an equals term, keeping any negation.
  QueryCond<T> call(T v) => QueryCond<T>._(key, v, negate: negate);
  @override
  bool test(Object? v) {
    final m = presence ? v != null : v == expected;
    return negate ? !m : m;
  }

  static QueryCond<String> get q =>
      const QueryCond._('q', null, presence: true);
  static const QueryNot not = QueryNot._();
}

final class QueryNot {
  const QueryNot._();
  QueryCond<String> get q =>
      const QueryCond._('q', null, presence: true, negate: true);
}

/// Screen-local query view-state for `catalog` (read-only).
class CatalogQuery {
  const CatalogQuery._();
  String? get q => _Screens.graph.viewGet(_Screens.catalog, 'q') as String?;
}

/// Mutable [CatalogQuery] — set a key (null clears / removes from URL).
final class CatalogQueryMut extends CatalogQuery {
  const CatalogQueryMut._() : super._();
  set q(String? v) => _Screens.graph.viewSet(_Screens.catalog, 'q', v);
}

/// `Catalog` query condition terms — `.key` present / `.key(v)` equals / `.flag` true; `.not.…` negates (`.not.key` = absent).
final class CatalogQueryCond<T> implements ViewCond {
  const CatalogQueryCond._(
    this.key,
    this.expected, {
    this.negate = false,
    this.presence = false,
  });
  @override
  final String key;
  final Object? expected;
  final bool negate;
  final bool presence;

  /// `.key(v)` — narrow a present term to an equals term, keeping any negation.
  CatalogQueryCond<T> call(T v) =>
      CatalogQueryCond<T>._(key, v, negate: negate);
  @override
  bool test(Object? v) {
    final m = presence ? v != null : v == expected;
    return negate ? !m : m;
  }

  static CatalogQueryCond<String> get q =>
      const CatalogQueryCond._('q', null, presence: true);
  static const CatalogQueryNot not = CatalogQueryNot._();
}

final class CatalogQueryNot {
  const CatalogQueryNot._();
  CatalogQueryCond<String> get q =>
      const CatalogQueryCond._('q', null, presence: true, negate: true);
}

/// `Catalog` query build terms — `.key(v)` sets a value, `.flag` sets a flag. No `.not` (build, not match).
final class CatalogQueryArg {
  const CatalogQueryArg._(this.key, this.value);
  final String key;
  final Object? value;
  static CatalogQueryArg q(String v) => CatalogQueryArg._('q', v);
}

/// Read-only view-state of `catalog` — the reactive reads return
/// this; the navigable `CatalogNav` adds the setters.
abstract interface class CatalogView implements AnyView {
  CatalogQuery get query;
}

AnyView? _viewOf(Enum? screen) => switch (screen) {
  _Screens.catalog => const CatalogNav._(),
  _ => null,
};

/// Reactive read-only stack reads scoped to this BuildContext.
extension ScreenStackContext on BuildContext {
  /// FOREGROUND: the typed read-only view if [sel] is the current front
  /// (suffix + ids + conditions), else null. Reactive on top + keys.
  V? on<N extends AnyNav, V>(On<N, V> sel) {
    if (sel.specs.isNotEmpty) Placement.isCurrent(this, sel.specs.last);
    ViewMatch.conds(this, _termOf(sel), sel.conds);
    return Screen.on(sel) != null ? _viewOf(_termOf(sel)) as V? : null;
  }

  /// ANYWHERE on the stack (front OR buried): the typed read-only view if
  /// [sel] is on the live stack, else null. Reactive on chain + keys.
  V? at<N extends AnyNav, V>(On<N, V> sel) {
    if (sel.specs.isNotEmpty) Placement.isOn(this, sel.specs.last);
    ViewMatch.conds(this, _termOf(sel), sel.conds);
    return Screen.at(sel) != null ? _viewOf(_termOf(sel)) as V? : null;
  }
}

Enum _termOf(On sel) =>
    sel.specs.isEmpty ? _Screens.graph.current : sel.specs.last;
