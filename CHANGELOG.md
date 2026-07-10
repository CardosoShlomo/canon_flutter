## 0.8.0

- canon ^0.28.0 (the engine folds: NavOps over NavState).
- Identity ambience: `ScreenScope`, `EntityScope`, and the new `IdScope` all plant their id, NODE-TAGGED (the screen's grammar node; the store's generated tag; `IdScope(node:)`) — typed reads resolve to the nearest MATCHING node, so erasure can never answer with another identity's id; untagged plants stay wildcards. `IdScope.of<K>(context)` reads the ambient id, `IdScope.navOf<K>(context)` mints the deictic `IdNav` handle, `IdScope.screenOf<K>`/`itemOf<K>` read one source only; `EntityScope.idOf` reads the entity's only, `context.idOf(.screen)` a named screen's.
- `store.item(id, child: …)` — the itemBuilder spelling of planting an `EntityScope`.
- Ambient-id reads: `store.entityOf(context, [id])` (the keyed reactive read — ambient id when omitted, explicit when passed; replaces `store(id).of(context)`), `store.idOf(context)` (the enclosing scope's id ONLY if planted from this store — identity with provenance, null otherwise), and `setUnit.containsIdOf(context)` (the in-flight membership idiom).

## 0.7.0

- BREAKING: `loadingOf` removed — in-flight status is a ledger row; read it with `of`.
- canon ^0.27.0.

## 0.6.0

- canon ^0.26.0 (the read-callback guard wave).

## 0.5.0

- canon ^0.25.0, canon_codec ^0.3.0.

## 0.4.0

- `FragmentPath.of` reactive read; canon 0.23 wave.

## 0.3.0

- The canon 0.22 / regent 0.4 wave.

## 0.2.1

- Track canon 0.21.1 (regent 0.3 line).

## 0.2.0

- `ScreenScope` wraps the consumer's page chrome (the `chrome` hook) — context reads work in scaffolds and nav bars.

# Changelog

## 0.1.1

- README leads with the Flutter-binding identity.

## 0.1.0

- Initial release: the Flutter presentation binding for pure-Dart `canon` — `NavHost` delegate, `ScreenScope`/`EntityScope`, reactive reads (`store(id).of(context)`, `Unit.of`, `loadingOf`, `Query`/`Fragment` view-state), path URL strategy.

- Initial release: the Flutter layer split out of canon.
