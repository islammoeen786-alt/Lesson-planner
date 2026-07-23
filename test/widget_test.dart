import 'package:flutter_test/flutter_test.dart';
import 'package:smart_lesson_planner/main.dart';
import 'package:smart_lesson_planner/services/theme_service.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    final themeService = ThemeService();
    await tester.pumpWidget(SmartLessonPlannerApp(themeService: themeService));
    await tester.pump();
    expect(find.byType(SmartLessonPlannerApp), findsOneWidget);
  });
}
