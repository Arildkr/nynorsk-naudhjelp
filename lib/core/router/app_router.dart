import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/assessment/presentation/assessment_intro_screen.dart';
import '../../features/assessment/presentation/assessment_flow_screen.dart';
import '../../features/grammar/presentation/grammar_screen.dart';
import '../../features/dashboard/presentation/statistics_screen.dart';
import '../../features/practice/presentation/practice_flow_screen.dart';
import '../../features/practice/presentation/category_picker_screen.dart';
import '../../features/teacher_mode/presentation/teacher_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/assessment',
        builder: (context, state) => const AssessmentIntroScreen(),
      ),
      GoRoute(
        path: '/assessment/flow',
        builder: (context, state) => const AssessmentFlowScreen(),
      ),
      GoRoute(
        path: '/grammar',
        builder: (context, state) => const GrammarScreen(),
      ),
      GoRoute(
        path: '/results',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/practice',
        builder: (context, state) => const CategoryPickerScreen(),
      ),
      GoRoute(
        path: '/practice/flow',
        builder: (context, state) => const PracticeFlowScreen(),
      ),
      GoRoute(
        path: '/practice/category/:cat',
        builder: (context, state) => PracticeFlowScreen(
          category: state.pathParameters['cat'],
        ),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboardScreen(),
      ),
    ],
  );
});
