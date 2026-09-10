import 'package:flutter_test/flutter_test.dart';
import 'package:speech_translator/models/fln_models.dart';
import 'package:speech_translator/service/fln/fln_curriculum_data.dart';
import 'package:speech_translator/service/fln/worksheet_generator_service.dart';
import 'package:speech_translator/service/fln/worksheet_pdf_service.dart';
import 'package:speech_translator/service/offline/offline_translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FLN Curriculum & NIPUN Bharat Suite Tests', () {
    test('NIPUN Competencies are defined for both Literacy and Numeracy across grades', () {
      final comps = FlnCurriculumData.competencies;
      expect(comps.isNotEmpty, isTrue);

      final literacyComps = comps.where((c) => c.subject == FlnSubject.literacy).toList();
      final numeracyComps = comps.where((c) => c.subject == FlnSubject.numeracy).toList();

      expect(literacyComps.isNotEmpty, isTrue);
      expect(numeracyComps.isNotEmpty, isTrue);

      // Check codes format
      for (var c in comps) {
        expect(c.code.startsWith('FL-') || c.code.startsWith('FN-'), isTrue);
        expect(c.titleHindi.isNotEmpty, isTrue);
        expect(c.titleSantali.isNotEmpty, isTrue);
        expect(c.learningOutcome.isNotEmpty, isTrue);
      }
    });

    test('Lesson Scripts contain structured 5-phase flows with Hindi and Santali text', () {
      final scripts = FlnCurriculumData.lessonScripts;
      expect(scripts.length, greaterThanOrEqualTo(3));

      for (var s in scripts) {
        expect(s.phases.length, equals(5));
        expect(s.totalDurationMinutes, greaterThan(0));
        expect(s.materialsNeeded.isNotEmpty, isTrue);

        for (var p in s.phases) {
          expect(p.teacherDialogueHindi.isNotEmpty, isTrue);
          expect(p.santaliOlChiki.isNotEmpty, isTrue);
          expect(p.santaliLatin.isNotEmpty, isTrue);
          expect(p.santaliDevanagari.isNotEmpty, isTrue);
        }
      }
    });

    test('Classroom Instructions soundboard has essential management and praise phrases', () {
      final instructions = FlnCurriculumData.classroomInstructions;
      expect(instructions.length, greaterThanOrEqualTo(10));

      final categories = instructions.map((i) => i.category).toSet();
      expect(categories.contains('Classroom Management'), isTrue);
      expect(categories.contains('Praise & Encouragement'), isTrue);
      expect(categories.contains('Focus & Attention'), isTrue);

      for (var inst in instructions) {
        expect(inst.hindi.isNotEmpty, isTrue);
        expect(inst.santaliOlChiki.isNotEmpty, isTrue);
        expect(inst.santaliLatin.isNotEmpty, isTrue);
        expect(inst.pedagogicalTip.isNotEmpty, isTrue);
      }
    });

    test('Assessment Prompts contain 3-tier NIPUN grading rubrics', () {
      final prompts = FlnCurriculumData.assessmentPrompts;
      expect(prompts.isNotEmpty, isTrue);

      for (var ap in prompts) {
        expect(ap.competencyCode.isNotEmpty, isTrue);
        expect(ap.promptHindi.isNotEmpty, isTrue);
        expect(ap.promptSantaliOlChiki.isNotEmpty, isTrue);
        expect(ap.rubricBeginning.isNotEmpty, isTrue);
        expect(ap.rubricProgressing.isNotEmpty, isTrue);
        expect(ap.rubricProficient.isNotEmpty, isTrue);
      }
    });

    test('Visual Flashcards cover vocabulary categories and contain Ol Chiki & phonetics', () {
      final flashcards = FlnCurriculumData.flashcards;
      expect(flashcards.length, greaterThanOrEqualTo(15));

      final animals = flashcards.where((f) => f.category == 'Animals').toList();
      final numbers = flashcards.where((f) => f.category == 'Numbers').toList();
      final body = flashcards.where((f) => f.category == 'Body Parts').toList();

      expect(animals.isNotEmpty, isTrue);
      expect(numbers.isNotEmpty, isTrue);
      expect(body.isNotEmpty, isTrue);

      for (var fc in flashcards) {
        expect(fc.hindi.isNotEmpty, isTrue);
        expect(fc.santaliOlChiki.isNotEmpty, isTrue);
        expect(fc.santaliLatin.isNotEmpty, isTrue);
        expect(fc.exampleSentenceHindi.isNotEmpty, isTrue);
        expect(fc.exampleSentenceSantali.isNotEmpty, isTrue);
      }
    });

    test('Worksheet Generator produces valid Literacy and Numeracy worksheets', () {
      final litWs = WorksheetGeneratorService.generateWorksheet(
        grade: FlnGrade.grade1,
        subject: FlnSubject.literacy,
      );

      expect(litWs.items.length, equals(4));
      expect(litWs.subject, equals(FlnSubject.literacy));
      expect(litWs.instructionsHindi.isNotEmpty, isTrue);
      expect(litWs.instructionsSantali.isNotEmpty, isTrue);

      final numWs = WorksheetGeneratorService.generateWorksheet(
        grade: FlnGrade.balvatika,
        subject: FlnSubject.numeracy,
      );

      expect(numWs.items.length, equals(4));
      expect(numWs.subject, equals(FlnSubject.numeracy));

      // Test plain text formatting and answer key
      final formattedText = WorksheetGeneratorService.formatWorksheetAsText(numWs, includeAnswerKey: true);
      expect(formattedText.contains("JHARKHAND PALASH"), isTrue);
      expect(formattedText.contains("TEACHER ANSWER KEY"), isTrue);
    });

    test('Offline Translator translates new FLN educational terms', () {
      final res1 = OfflineTranslator.translate(
        text: 'किताब खोलो',
        fromLang: 'hi',
        toLang: 'sat',
      );
      expect(res1.translatedText, equals('ᱯᱩᱛᱷᱤ ᱡᱷᱤᱡᱽᱯᱮ'));

      final res2 = OfflineTranslator.translate(
        text: 'स्कूल',
        fromLang: 'hi',
        toLang: 'sat',
      );
      expect(res2.translatedText, equals('ᱟᱥᱲᱟ'));

      final res3 = OfflineTranslator.translate(
        text: 'शिक्षक',
        fromLang: 'hi',
        toLang: 'sat',
      );
      expect(res3.translatedText, equals('ᱜᱩᱨᱩ ᱜᱚᱢᱠᱮ'));
    });

    test('WorksheetPdfService generates valid PDF document bytes', () async {
      final ws = WorksheetGeneratorService.generateWorksheet(
        grade: FlnGrade.balvatika,
        subject: FlnSubject.literacy,
      );

      final pdfDoc = await WorksheetPdfService.generatePdf(ws, includeAnswerKey: true);
      final bytes = await pdfDoc.save();
      expect(bytes.isNotEmpty, isTrue);
      // PDF documents start with %PDF- header (0x25, 0x50, 0x44, 0x46)
      expect(bytes[0], equals(0x25));
      expect(bytes[1], equals(0x50));
      expect(bytes[2], equals(0x44));
      expect(bytes[3], equals(0x46));
    });
  });
}
