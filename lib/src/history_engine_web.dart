import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_web_plugins/url_strategy.dart' show usePathUrlStrategy;

/// Switch the engine to clean PATH urls (no `#`) — canon's default.
void usePathUrls() => usePathUrlStrategy();

/// Put the Flutter engine in multi-entry history mode so browser back/forward
/// are real history navigations (the single-entry default cancels back).
Future<void> enableMultiEntryHistory() =>
    SystemNavigator.selectMultiEntryHistory();
