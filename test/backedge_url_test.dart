import 'package:flutter/material.dart';
import 'package:canon_flutter/canon_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

enum T with ScreenNode<T> { a, b; @override Widget get widget => const SizedBox.shrink(); }
class _Init implements RootScreenBase { const _Init(this.chain); @override final List<(Enum, Object?)> chain; }
ScreenGraph _mk() => ScreenGraph({ T.a({ T.b({T.a.again}) }) }, seedChain: const _Init([(T.a, null)]), pageOf: (w,c,k)=>MaterialPage(child:w));

void main() {
  test('a({b({a.again})}) URL follows the rule', () async {
    final g = _mk();
    expect(g.currentUrl(), '/a');
    g.go(T.b); await Future<void>.delayed(Duration.zero);
    expect(g.currentUrl(), '/a/b');
    g.go(T.a); await Future<void>.delayed(Duration.zero);  // a.again → push
    expect([for (final e in g.stack) e.screen.name], ['a','b','a']); // blob has depth 3
    expect(g.currentUrl(), '/a');                                     // URL is top-only
  });
}
