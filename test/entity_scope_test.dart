import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:canon_flutter/canon_flutter.dart';

class Product with Identifiable<String> {
  const Product({required this.id, required this.title});

  @override
  final String id;
  final String title;
}

sealed class ProductMsg extends Msg {
  const ProductMsg();
}

class ProductsMsg extends ProductMsg {
  const ProductsMsg(this.products);
  final List<Product> products;
}

class TitleChangedMsg extends ProductMsg {
  const TitleChangedMsg(this.id, this.title);
  final String id;
  final String title;
}

class Products extends Store<String, Product, ProductMsg> {
  const Products();

  @override
  IdentifiableMap<String, Product> reduce(
          IdentifiableMap<String, Product> entities, ProductMsg msg) =>
      switch (msg) {
        ProductsMsg(:final products) => products.toMapById(),
        TitleChangedMsg(:final id, :final title) => entities.updateById(
            id, (p) => Product(id: p.id, title: title)),
      };
}

/// Counts builds per item — the surgical-rebuild assertion.
final builds = <String, int>{};

class ProductCard extends StatelessWidget {
  const ProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    final product = EntityScope.of<Product>(context);
    builds.update(product.id, (n) => n + 1, ifAbsent: () => 1);
    return Text('${product.id}:${product.title}', textDirection: .ltr);
  }
}

void main() {
  testWidgets('EntityScope: ambient entity, surgical per-item rebuilds',
      (tester) async {
    final ledger = Ledger();
    final store = ledger.store(const Products());
    ledger.dispatch(const ProductsMsg([
      Product(id: 'a', title: 'one'),
      Product(id: 'b', title: 'two'),
    ]));

    await tester.pumpWidget(Column(
      children: [
        for (final id in store.entities.keys)
          EntityScope(store, id, child: const ProductCard()),
      ],
    ));
    expect(find.text('a:one'), findsOneWidget);
    expect(find.text('b:two'), findsOneWidget);
    expect(builds, {'a': 1, 'b': 1});

    // One entity updates → ONE item rebuilds.
    ledger.dispatch(const TitleChangedMsg('a', 'uno'));
    await tester.pump();
    await tester.pump();
    expect(find.text('a:uno'), findsOneWidget);
    expect(find.text('b:two'), findsOneWidget);
    expect(builds, {'a': 2, 'b': 1});

    // The id is ambient too.
    final context = tester.element(find.text('b:two'));
    expect(EntityScope.idOf<String>(context), 'b');
  });

  testWidgets('StoreBuilder: list build re-runs ONLY on add/remove/reorder',
      (tester) async {
    builds.clear();
    var listBuilds = 0;
    final ledger = Ledger();
    final store = ledger.store(const Products());
    ledger.dispatch(const ProductsMsg([
      Product(id: 'a', title: 'one'),
      Product(id: 'b', title: 'two'),
    ]));

    await tester.pumpWidget(StoreBuilder(store, (context, ids) {
      listBuilds++;
      return Column(
        children: [
          for (final id in ids)
            EntityScope(store, id, child: const ProductCard()),
        ],
      );
    }));
    expect(listBuilds, 1);

    // Value update → the LIST build does not re-run; one item rebuilds.
    ledger.dispatch(const TitleChangedMsg('a', 'uno'));
    await tester.pump();
    await tester.pump();
    expect(listBuilds, 1);
    expect(builds, {'a': 2, 'b': 1});
    expect(find.text('a:uno'), findsOneWidget);

    // Add → the list build re-runs; existing items do NOT rebuild.
    ledger.dispatch(const ProductsMsg([
      Product(id: 'a', title: 'uno'),
      Product(id: 'b', title: 'two'),
      Product(id: 'c', title: 'three'),
    ]));
    await tester.pump();
    await tester.pump();
    expect(listBuilds, 2);
    expect(find.text('c:three'), findsOneWidget);
    expect(builds['b'], 1); // untouched neighbor never rebuilt
  });

  testWidgets('store.of(context): reactive ids read through the StoreHost',
      (tester) async {
    builds.clear();
    var listBuilds = 0;
    final ledger = Ledger();
    final store = ledger.store(const Products());
    ledger.dispatch(const ProductsMsg([Product(id: 'a', title: 'one')]));

    await tester.pumpWidget(StoreHost(
      child: Builder(builder: (context) {
        final ids = store.of(context);
        listBuilds++;
        return Column(
          children: [
            for (final id in ids)
              EntityScope(store, id, child: const ProductCard()),
          ],
        );
      }),
    ));
    expect(listBuilds, 1);

    // Value change → the ids read does NOT rebuild; the item does.
    ledger.dispatch(const TitleChangedMsg('a', 'uno'));
    await tester.pump();
    await tester.pump();
    expect(listBuilds, 1);
    expect(find.text('a:uno'), findsOneWidget);

    // Add → the ids read rebuilds.
    ledger.dispatch(const ProductsMsg([
      Product(id: 'a', title: 'uno'),
      Product(id: 'b', title: 'two'),
    ]));
    await tester.pump();
    await tester.pump();
    expect(listBuilds, 2);
    expect(find.text('b:two'), findsOneWidget);
  });

  testWidgets('store(id).of(context): nullable per-key value read',
      (tester) async {
    var builds = 0;
    final ledger = Ledger();
    final store = ledger.store(const Products());

    await tester.pumpWidget(StoreHost(
      child: Builder(builder: (context) {
        builds++;
        final p = store('a').of(context);
        return Text(p?.title ?? 'missing', textDirection: .ltr);
      }),
    ));
    expect(find.text('missing'), findsOneWidget);

    // Appears → rebuild.
    ledger.dispatch(const ProductsMsg([Product(id: 'a', title: 'one')]));
    await tester.pump();
    await tester.pump();
    expect(find.text('one'), findsOneWidget);

    // Unrelated key → NO rebuild.
    final before = builds;
    ledger.dispatch(const ProductsMsg([
      Product(id: 'a', title: 'one'),
      Product(id: 'b', title: 'x'),
    ]));
    await tester.pump();
    await tester.pump();
    expect(builds, before);

    // Changes → rebuild. Disappears → rebuild to missing.
    ledger.dispatch(const TitleChangedMsg('a', 'uno'));
    await tester.pump();
    await tester.pump();
    expect(find.text('uno'), findsOneWidget);
    ledger.dispatch(const ProductsMsg([]));
    await tester.pump();
    await tester.pump();
    expect(find.text('missing'), findsOneWidget);
  });
}
