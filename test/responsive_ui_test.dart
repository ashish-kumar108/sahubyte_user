import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/res/app_ui.dart';

void main() {
  testWidgets('shared user actions fit a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBottomAction(
                label: 'Continue with this service request',
                secondaryLabel: 'Choose another option',
                onPressed: () {},
                onSecondaryPressed: () {},
              ),
              AppBottomNav(currentIndex: 0, onTap: (_) {}),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('search field reports text and clears it', (tester) async {
    final controller = TextEditingController();
    var query = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: AppSearchField(
              hint: 'Search brands',
              controller: controller,
              onChanged: (value) => setState(() => query = value),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Samsung');
    await tester.pump();
    expect(query, 'Samsung');
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(query, isEmpty);
    expect(controller.text, isEmpty);
    controller.dispose();
  });
}
