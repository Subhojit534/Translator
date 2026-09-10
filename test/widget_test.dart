import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_translator/main.dart';

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

  testWidgets('App smoke test loads main navigation and home screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SantaliTranslatorApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Santali Translator'), findsOneWidget);
    expect(find.text('Classroom Edition'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);
    expect(find.text('FLN Hub'), findsOneWidget);
    expect(find.text('Conversation'), findsOneWidget);
    expect(find.text('Phrasebook'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Dictionary'), findsNothing);
    expect(find.text('Quick Classroom Phrases'), findsOneWidget);
  });

  testWidgets('Navigates across tabs properly and verifies FLN Hub features', (WidgetTester tester) async {
    await tester.pumpWidget(const SantaliTranslatorApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Tap FLN Hub tab
    await tester.tap(find.text('FLN Hub'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('PALASH MTB-MLE & NIPUN Bharat'), findsOneWidget);
    expect(find.text('पाठ योजना (Scripts)'), findsOneWidget);
    expect(find.text('शब्दावली (Vocabulary)'), findsOneWidget);
    expect(find.text('वर्णमाला (Ol Chiki)'), findsOneWidget);

    // Scroll tab bar left to reveal Vocabulary and Alphabet
    await tester.drag(find.byType(TabBar), const Offset(-250, 0));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Vocabulary sub-tab inside FLN Hub
    await tester.tap(find.text('शब्दावली (Vocabulary)'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(TextField), findsWidgets);

    // Tap Alphabet sub-tab inside FLN Hub
    await tester.drag(find.byType(TabBar), const Offset(-200, 0));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('वर्णमाला (Ol Chiki)'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('ᱚᱞ ᱪᱤᱠᱤ (Ol Chiki Script Literacy)'), findsOneWidget);

    // Tap Worksheets sub-tab inside FLN Hub
    await tester.drag(find.byType(TabBar), const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('कार्यपत्रक (Worksheets)'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('JHARKHAND PALASH MTB-MLE PROGRAMME'), findsOneWidget);
    expect(find.text('PDF डाउनलोड / प्रिंट'), findsOneWidget);

    // Tap Conversation tab
    await tester.tap(find.text('Conversation'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Classroom Conversation'), findsOneWidget);
    expect(find.text('Speak Hindi\n(Teacher)'), findsOneWidget);
    expect(find.text('Speak Santali\n(Student)'), findsOneWidget);

    // Tap Phrasebook tab
    await tester.tap(find.text('Phrasebook'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Classroom Phrasebook'), findsOneWidget);
    expect(find.text('Classroom'), findsWidgets);

    // Tap History tab
    await tester.tap(find.text('History'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('History & Favorites'), findsOneWidget);
    expect(find.text('No translation history yet'), findsOneWidget);
  });

  testWidgets('Translate tab enters text and displays Ol Chiki result',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SantaliTranslatorApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Enter Hindi text into input field
    final inputFinder = find.byType(TextField).first;
    await tester.enterText(inputFinder, 'नमस्ते');
    // Debounce timer is 350ms, plus translation
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));

    // Result should show Santali Ol Chiki translation 'ᱡᱚᱦᱟᱨ'
    expect(find.text('ᱡᱚᱦᱟᱨ'), findsWidgets);
    expect(find.text('Pronunciation: Johar'), findsOneWidget);
  });

  testWidgets('Renders all screens on 360x800 mobile screen without any RenderFlex overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400); // 360 x 800 at 3.0 dpr
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SantaliTranslatorApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Home screen check
    expect(find.text('Santali Translator'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Switch to FLN Hub
    await tester.tap(find.text('FLN Hub'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('PALASH MTB-MLE & NIPUN Bharat'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Switch to Phrasebook
    await tester.tap(find.text('Phrasebook'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Classroom Phrasebook'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Switch to Conversation
    await tester.tap(find.text('Conversation'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Classroom Conversation'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Switch to History
    await tester.tap(find.text('History'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('History & Favorites'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Language selector displays Hindi -> Santali, opens source/target dropdowns and supports swap',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SantaliTranslatorApp());
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify initial state: Hindi -> Santali
    expect(find.text("हिंदी (Hindi)"), findsOneWidget);
    expect(find.text("Santali"), findsOneWidget);

    // 2. Tap source language selector to open source dropdown
    await tester.tap(find.text("हिंदी (Hindi)"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text("SOURCE LANGUAGE"), findsOneWidget);
    expect(find.text("English"), findsOneWidget);

    // Select English
    await tester.tap(find.text("English"), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text("English"), findsOneWidget);

    // 3. Tap target language selector to open target dropdown
    await tester.tap(find.text("Santali"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text("TARGET LANGUAGE"), findsOneWidget);
    expect(find.text("Mundari"), findsOneWidget);
    expect(find.text("Ho"), findsOneWidget);

    // Select Mundari
    await tester.tap(find.text("Mundari"), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text("Mundari"), findsOneWidget);

    // Now current is English -> Mundari
    // 4. Tap swap button
    final swapFinder = find.byTooltip("Swap languages");
    expect(swapFinder, findsOneWidget);
    await tester.tap(swapFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Swapped: Mundari is source, English is target
    expect(find.text("Mundari"), findsOneWidget);
    expect(find.text("English"), findsOneWidget);

    // 5. Swap back
    await tester.tap(swapFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text("English"), findsOneWidget);
    expect(find.text("Mundari"), findsOneWidget);
  });

  testWidgets('FLN Hub Worksheets tab contains PALASH Worksheet Assistant chatbot with 5s simulated processing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SantaliTranslatorApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Navigate to FLN Hub
    await tester.tap(find.text('FLN Hub'));
    await tester.pump(const Duration(milliseconds: 300));

    // Switch directly to Worksheets tab (index 5)
    final tabController1 = DefaultTabController.of(tester.element(find.byType(TabBarView)));
    tabController1.animateTo(5);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Assistant widget exists
    final assistantTitle = find.text('PALASH Worksheet Assistant');
    await tester.ensureVisible(assistantTitle);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('PALASH Worksheet Assistant'), findsOneWidget);
    expect(find.text("Tell me what you need — I'll prepare the worksheet."), findsOneWidget);
    expect(find.text('Example: "Make this worksheet ready"'), findsOneWidget);

    // Tap the example suggestion to populate the TextField
    final exampleFinder = find.text('Example: "Make this worksheet ready"');
    await tester.ensureVisible(exampleFinder);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(exampleFinder);
    await tester.pump();
    expect(find.text('Make this worksheet ready'), findsOneWidget);

    // Press enter to submit
    final chatInput = find.widgetWithText(TextField, 'Make this worksheet ready');
    await tester.showKeyboard(chatInput);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    // 0s: Processing starts
    expect(find.text('Preparing your worksheet...'), findsOneWidget);

    // Advance 2 seconds -> Formatting activities...
    await tester.pump(const Duration(milliseconds: 2100));
    expect(find.text('Formatting activities...'), findsOneWidget);

    // Advance 2 more seconds (total ~4.1s) -> Creating PDF...
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.text('Creating PDF...'), findsOneWidget);

    // Advance to 5+ seconds -> PDF generated, success message displayed
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    expect(find.text('✓ Worksheet PDF ready'), findsOneWidget);

    // After 2 seconds, resets to normal
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text("Tell me what you need — I'll prepare the worksheet."), findsOneWidget);
    // Allow any SnackBar to complete
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Worksheet Assistant handles arbitrary prompt and send button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SantaliTranslatorApp());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('FLN Hub'));
    await tester.pump(const Duration(milliseconds: 300));

    // Switch directly to Worksheets tab (index 5)
    final tabController2 = DefaultTabController.of(tester.element(find.byType(TabBarView)));
    tabController2.animateTo(5);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));

    // Ensure Assistant card is visible
    final assistantTitle = find.text('PALASH Worksheet Assistant');
    await tester.ensureVisible(assistantTitle);
    await tester.pump(const Duration(milliseconds: 200));

    final sendBtnFinder = find.byTooltip('Send request');
    expect(sendBtnFinder, findsOneWidget);

    // Type arbitrary prompt: "Make this easier"
    final chatInputFinder = find.byType(TextField);
    await tester.enterText(chatInputFinder, 'Make this easier');
    await tester.pump();

    // Tap Send button
    await tester.tap(sendBtnFinder, warnIfMissed: false);
    await tester.pump();
    expect(find.text('Preparing your worksheet...'), findsOneWidget);

    // Advance to completion
    await tester.pump(const Duration(milliseconds: 5100));
    await tester.pump();
    expect(find.text('✓ Worksheet PDF ready'), findsOneWidget);

    // Reset
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text("Tell me what you need — I'll prepare the worksheet."), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}


