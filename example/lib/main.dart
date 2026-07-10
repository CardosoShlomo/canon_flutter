import 'package:flutter/material.dart';
import 'package:canon_flutter/canon_flutter.dart';

part 'main.canon.dart';

// ── WEB NAVIGATION, whole and minimal: one grammar tree. ─────────────────
// A grammar-only consumer: the router runs on its local fold. What this one
// enum buys on the web:
//
//   * the URL is a PROJECTION of the committed stack
//   * browser back/forward walk REAL history entries (raw History API)
//   * refresh restores the EXACT stack, state included
//   * a cold deep link rebuilds the legal CHAIN below the target
//   * `?query` is typed view-state, mirrored to the URL, restored with it
//   * every expressible navigation is a legal one — the verbs ARE the edges
//
// Run it: `flutter run -d chrome`. Then: navigate around, hit browser back,
// refresh mid-stack, and paste  /catalog/product/<uuid>  cold.

// The identity space: one node, one codec — `ProductId` generates from it.
@canon
enum Ids with IdNode {
  product(.uuid);

  const Ids(this.codec);
  @override
  final Codec codec;
}

// Catalog view-state: the `?q=` filter — typed, URL-real, restorable.
enum CatalogQ with QueryKeyBase { q }

@canon
enum _Screens with ScreenNode<_Screens> {
  catalog(_Catalog()),
  product(_Product(), .product), // id-keyed: /catalog/product/<uuid>
  orders(_Page('Orders', Color(0xFF00897B))),
  about(_Page('About', Color(0xFF5E35B1)));

  const _Screens(this.widget, [this.id]);
  @override
  final Widget widget;
  @override
  final Ids? id;

  static final graph = NavGraph(
    {
      Domain('https://shop.example'),
      // `keep`: the catalog's stack survives switching to another trunk.
      catalog.keep({product}).query({CatalogQ.q(.string)}),
      orders,
      about,
      // A shareable ingress: /product/<uuid> resolves INTO the catalog chain.
      product.link({slot(Ids.product)}),
    },
    root: const ColoredBox(color: Colors.white),
    pageOf: (widget, ctx, key) => MaterialPage(key: key, child: widget),
  );
}

void main() {
  // The cold-start resolver: a landing URL commits its place (the deep
  // link case); a bare `/` commits the catalog.
  Screen.resolver = (url) {
    if (url case final Place p) {
      Screen.go(p);
    } else {
      Screen.goCatalog();
    }
  };
  runApp(MaterialApp.router(routerDelegate: Screen.manager));
}

// ── Screens ──
class _Catalog extends StatelessWidget {
  const _Catalog();

  @override
  Widget build(BuildContext context) {
    final q = Query.of(context, CatalogQ.q) ?? '';
    final products = [
      for (var i = 1; i <= 5; i++)
        ('0000000$i-0000-4000-8000-00000000000$i', 'product $i'),
    ].where((p) => p.$2.contains(q));
    return Scaffold(
      appBar: AppBar(title: const Text('catalog')),
      body: Column(children: [
        TextField(
          decoration: const InputDecoration(hintText: 'filter — lives in ?q='),
          // Typed view-state WRITE: mirrors to the URL, restores on refresh.
          onChanged: (v) => Screen.on(.catalog)?.query.q = v,
        ),
        for (final (id, name) in products)
          ListTile(
            title: Text(name),
            // A generated edge verb — typed, and URL-real on commit.
            onTap: () => Screen.on(.catalog)?.goProduct(ProductId(id)),
          ),
        const Divider(),
        TextButton(onPressed: Screen.goOrders, child: const Text('orders')),
        TextButton(onPressed: Screen.goAbout, child: const Text('about')),
      ]),
    );
  }
}

class _Product extends StatelessWidget {
  const _Product();

  @override
  Widget build(BuildContext context) {
    // Ambient identity: the screen's typed id from the committed stack —
    // the same read serves a tap, a refresh, and a cold deep link.
    final ProductId id = context.idOf(.product);
    return Scaffold(
      appBar: AppBar(
        title: Text('product $id'),
        leading: BackButton(onPressed: Screen.pop), // = browser back
      ),
      body: const Center(child: Text('refresh me — the stack survives')),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page(this.title, this.color);
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: color),
      body: Center(
        child: TextButton(
            onPressed: Screen.goCatalog, child: const Text('catalog')),
      ),
    );
  }
}
