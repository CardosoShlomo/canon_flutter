/// Flutter bindings for canon: the router delegate/manager, screen scope,
/// and reactive view-state widgets. Re-exports canon — consumers import
/// only this.
library;

export 'package:canon/canon.dart' hide NavScope, NavSlot;

// ScreenScope is @internal (the delegate wraps pages with it; the generated
// extension calls its statics). Exported so generated code resolves it.
// ignore: invalid_export_of_internal_element
export 'src/scopes.dart' hide ViewModel, PlacementModel, ScopeLiveness;
export 'src/router.dart';
