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
    expect(find.text('a:uno'), findsOneWidget);
    expect(find.text('b:two'), findsOneWidget);
    expect(builds, {'a': 2, 'b': 1});

    // The id is ambient too.
    final context = tester.element(find.text('b:two'));
    expect(EntityScope.idOf<String>(context), 'b');
  });
}
