import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/main.dart';

void main() {
  testWidgets('shows the branded splash screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Tech support, made simple.'), findsOneWidget);
    expect(find.byType(MyApp), findsOneWidget);
  });
}
