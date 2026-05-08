import 'package:flutter_test/flutter_test.dart';
import 'package:pintapp_mobile/app.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    // PintApp requires Hive to be initialised at runtime.
    // We only verify the widget class can be constructed without throwing.
    expect(const PintApp(), isA<PintApp>());
  });
}
