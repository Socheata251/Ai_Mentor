import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mentor/features/ai_tutor/screens/ai_tutor_screen.dart';
import 'package:mentor/features/ai_tutor/screens/chat_prompt_history_screen.dart';
import 'package:mentor/data/services/ai_service.dart';
import 'package:mentor/data/models/message.dart';
import 'package:mentor/features/progress/screens/progress_screen.dart';
import 'package:mentor/features/quiz/screens/quiz_screen.dart';
import 'package:mentor/features/schedule/screens/schedule_screen.dart';
import 'package:mentor/features/settings/screens/settings_screen.dart';
import 'package:mentor/core/theme/app_theme.dart';
import 'package:mentor/core/widgets/brand_logo.dart';
import 'package:mentor/screens/onboarding_screen.dart';
import 'package:mentor/screens/home_screen.dart';

Widget _testApp(Widget home, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  builder: (context, child) =>
      DefaultAssetBundle(bundle: _TestAssetBundle(), child: child!),
  home: home,
);

class _TestAssetBundle extends CachingAssetBundle {
  static final _pixel = ByteData.sublistView(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
    ),
  );

  @override
  Future<ByteData> load(String key) async {
    if (key == 'assets/logo.png' || key == 'assets/nav_logo.png') {
      return _pixel;
    }
    return rootBundle.load(key);
  }
}

void main() {
  testWidgets('Get Started navigates to the home dashboard', (tester) async {
    await tester.pumpWidget(_testApp(const OnboardingScreen()));

    expect(find.text('Get Started'), findsOneWidget);

    final state = tester.state(find.byType(OnboardingScreen));
    (state as dynamic).onStart();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('Settings screen renders its preferences', (tester) async {
    await tester.pumpWidget(_testApp(const SettingsScreen()));
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Tutor preferences'), findsOneWidget);
  });

  testWidgets('Schedule screen renders planned learning sessions', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const ScheduleScreen()));

    expect(find.byType(ScheduleScreen), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.text('Daily Coding Brief'), findsOneWidget);
  });

  testWidgets('Home top bar follows the dark theme', (tester) async {
    await tester.pumpWidget(
      _testApp(const DashboardScreen(), theme: AppTheme.dark),
    );
    final topBarLabel = tester.widget<Text>(find.text('AI STUDY MODE'));

    expect(
      topBarLabel.style?.color,
      AppTheme.dark.extension<AppColors>()!.textStrong,
    );
  });

  testWidgets('Home logos and composer fit phone and tablet widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 740);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(const DashboardScreen()));
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.byType(BrandLogo), findsOneWidget);
    expect(find.byType(NavLogo), findsAtLeastNWidgets(3));
    expect(find.text('Ask anything...'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(900, 900);
    await tester.pump();
    expect(find.text('Ask anything...'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home drawer is white and omits unused destinations', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const DashboardScreen()));
    tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
    await tester.pump(const Duration(milliseconds: 350));

    final drawer = tester.widget<Drawer>(find.byType(Drawer));
    expect(
      drawer.backgroundColor,
      AppTheme.light.extension<AppColors>()!.surface,
    );
    expect(find.text('Code Playground'), findsNothing);
    expect(find.text('Achievements'), findsNothing);
  });

  testWidgets('Progress screen shows stats and opens quiz', (tester) async {
    await tester.pumpWidget(_testApp(const ProgressScreen()));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(ListView)).height, greaterThan(0));
    expect(find.text('Your Progress'), findsOneWidget);
    expect(find.text('Questions answered'), findsOneWidget);
    expect(find.text('Recursion'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pump();
    expect(find.text('Study streak: 5 days'), findsOneWidget);

    await tester.tap(find.text('Generate Quiz on Recursion (10 Qs)'));
    await tester.pumpAndSettle();

    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.text('Choose a topic'), findsOneWidget);
  });

  testWidgets('Quiz lets the user start a topic', (tester) async {
    await tester.pumpWidget(_testApp(const QuizScreen()));
    expect(find.text('Choose a topic'), findsOneWidget);
    expect(find.text('JavaScript Core'), findsOneWidget);
    await tester.tap(find.text('JavaScript Core'));
    await tester.pump();

    expect(find.textContaining('Which method is used to add'), findsOneWidget);
    await tester.ensureVisible(find.text('push()'));
    await tester.tap(find.text('push()'));
    await tester.pump();
    expect(find.text('Correct!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('02 / 06'), findsAtLeastNWidgets(1));
    expect(find.text('Next Question'), findsNothing);
  });

  testWidgets('Tutor sends its initial question', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const AiTutorScreen(useDemo: false, initialPrompt: 'Explain arrays'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(AiTutorScreen), findsOneWidget);
    expect(find.text('Explain arrays'), findsOneWidget);
  });

  testWidgets('Tutor history shows the questions the user asked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const AiTutorScreen(useDemo: false, initialPrompt: 'Explain arrays'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byTooltip('Your questions'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatPromptHistoryScreen), findsOneWidget);
    expect(find.text('Explain arrays'), findsNWidgets(2));
  });

  testWidgets('Tutor history resumes the selected conversation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const AiTutorScreen(
          useDemo: false,
          initialPrompt: 'Reopen this saved conversation',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byTooltip('Your questions'));
    await tester.pumpAndSettle();

    expect(find.text('Chat & Practice History'), findsOneWidget);
    expect(find.text('Reopen this saved conversation'), findsOneWidget);

    await tester.tap(find.text('Reopen this saved conversation'));
    await tester.pumpAndSettle();

    expect(find.byType(AiTutorScreen), findsOneWidget);
    expect(find.text('Reopen this saved conversation'), findsOneWidget);
  });

  test('Mock tutor replies in the selected language', () async {
    const service = MockAiService();
    final history = <ChatMessage>[];
    final khmerReply = await service.reply(
      history: history,
      userText: 'Explain arrays',
      responseLanguage: 'Khmer',
    );
    final englishReply = await service.reply(
      history: history,
      userText: 'Explain arrays',
      responseLanguage: 'English',
    );

    expect(khmerReply.plainText, contains('សំណួរល្អណាស់'));
    expect(englishReply.plainText, contains('Good question'));
  });
}
