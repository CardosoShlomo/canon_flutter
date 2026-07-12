import 'package:flutter/material.dart';
import 'package:canon_flutter/canon_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

// A graph seeded with a boot widget starts at BootScreen.root (the synthetic
// loading placement). The first navigation out of boot auto-replaces — the
// loading screen leaves no history, so the resolver stays cold/warm-unaware.
enum R with ScreenNode<R> {
  home,
  feed;

  @override
  Widget get widget => const SizedBox.shrink();
}

class _Init implements RootScreenBase {
  const _Init(this.chain);
  @override
  final List<(Enum, Object?)> chain;
}

ScreenGraph _boot() => ScreenGraph(
      {R.home(), R.feed()},
      root: const SizedBox.shrink(),
      pageOf: (w, c, k) => MaterialPage(child: w),
    );

void main() {
  test('seeds the synthetic boot placement', () {
    expect(_boot().current, BootScreen.root);
  });

  test('first commit out of boot is an auto-replace', () async {
    final graph = _boot();
    final modes = <CommitMode>[];
    graph.navigations.listen((n) => modes.add(n.mode));

    graph.go(R.home);
    await Future<void>.delayed(Duration.zero);

    expect(graph.current, R.home);
    expect(modes, [CommitMode.replace]);
  });

  test('a subsequent navigation pushes normally', () async {
    final graph = _boot();
    final modes = <CommitMode>[];
    graph.navigations.listen((n) => modes.add(n.mode));

    graph.go(R.home);
    await Future<void>.delayed(Duration.zero);
    graph.go(R.feed);
    await Future<void>.delayed(Duration.zero);

    expect(modes, [CommitMode.replace, CommitMode.push]);
  });
}
