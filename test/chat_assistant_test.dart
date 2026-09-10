import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_translator/ui/screens/fln_curriculum_hub_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall methodCall) async {
      return '.';
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('net.nfet.printing'), (MethodCall methodCall) async {
      return 1;
    });
  });

  testWidgets('Worksheet Assistant 5-second simulated flow test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FlnCurriculumHubScreen(initialTabIndex: 5),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Assistant widget exists
    expect(find.text('PALASH Worksheet Assistant'), findsOneWidget);
    expect(find.text("Tell me what you need — I'll prepare the worksheet."), findsOneWidget);

    final chatInput = find.widgetWithText(TextField, 'Type your request...');
    expect(chatInput, findsOneWidget);

    // 1. Test empty input: should NOT start processing
    final sendBtn = find.byTooltip('Send request');
    await tester.tap(sendBtn);
    await tester.pump();
    expect(find.text('Preparing your worksheet...'), findsNothing);

    // 2. Test example chip
    await tester.tap(find.text('Example: "Make this worksheet ready"'));
    await tester.pump();
    expect(find.text('Make this worksheet ready'), findsOneWidget);

    // 3. Test submitting
    await tester.tap(sendBtn);
    await tester.pump();

    // 0s: Processing starts
    expect(find.text('Preparing your worksheet...'), findsOneWidget);

    // 2s: Formatting activities...
    await tester.pump(const Duration(milliseconds: 2100));
    expect(find.text('Formatting activities...'), findsOneWidget);

    // 4s: Creating PDF...
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.text('Creating PDF...'), findsOneWidget);

    // 5s: Triggers PDF generation
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    expect(find.text('✓ Worksheet PDF ready'), findsOneWidget);

    // After 2s: Resets to idle state
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text("Tell me what you need — I'll prepare the worksheet."), findsOneWidget);
  });

  testWidgets('Worksheet Assistant handles arbitrary prompt and ENTER key', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FlnCurriculumHubScreen(initialTabIndex: 5),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final chatInput = find.widgetWithText(TextField, 'Type your request...');
    await tester.enterText(chatInput, 'Make it easier');
    await tester.pump();

    // Press ENTER
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    // Processing starts
    expect(find.text('Preparing your worksheet...'), findsOneWidget);

    // Advance 5 seconds
    await tester.pump(const Duration(milliseconds: 5100));
    await tester.pump();
    expect(find.text('✓ Worksheet PDF ready'), findsOneWidget);
  });
}
