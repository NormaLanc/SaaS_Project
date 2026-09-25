import 'package:family_saas/Pages/App/invites.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Pages/landing_page.dart';
import '../Pages/sign_in.dart';
import '../Pages/create_account.dart';
import '../Pages/App/family_dashboard.dart';
import '../Pages/App/settings.dart';
import '../Pages/App/profile_page.dart';
import '../Pages/App/join_family.dart';
import '../Pages/App/create_family.dart';
import '../Pages/App/family_page.dart';
import '../Pages/App/add_child_page.dart';
import '../Pages/App/child_profile.dart';
import '../Pages/App/Milestones/add_milestones.dart';
import '../Pages/App/Photos/add_photo.dart';
import '../Pages/App/Calendar/family_calendar.dart';
import '../Pages/App/Calendar/add_event.dart';
import '../Pages/App/Documents/add_document.dart';
import '../Pages/App/Notifications/notifications.dart';
import '../Pages/App/intro_page.dart';
import '../Pages/splash_page.dart';
import '../Pages/App/families_page.dart';

final GoRouter appRouter = GoRouter(
  // initialLocation: kIsWeb ? '/' : '/welcome',
  // initialLocation: kIsWeb ? '/' : '/login',
   initialLocation: kIsWeb ? '/' : '/splash',


  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    debugPrint('ROUTER SESSION: ${session?.user.id}',);

    debugPrint('ROUTER PATH: ${state.uri.path}',);

    final path = state.uri.path;

    final isPublicPage =
        path == '/' ||
        path == '/splash' || 
        path == '/welcome' ||
        path == '/login' ||
        path == '/register';

    if (!isLoggedIn && !isPublicPage) {
      debugPrint('ROUTER: Redirecting to /login');
      return '/login';
    }

    if (isLoggedIn &&
        (path == '/welcome' ||
          path == '/login' || 
        path == '/register')) {
          debugPrint('ROUTER: Redirecting to /app');
      return '/app';
    }

    return null;
  },

  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/app',
      builder: (context, state) => const FamilyDashboard(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/join-family',
      builder: (context, state) => const JoinFamilyPage(),
    ),
    GoRoute(
      path: '/create-family',
      builder: (context, state) => const CreateFamilyPage(),
    ),
    GoRoute(
      path: '/invitations',
      builder: (context, state) => const InvitesPage(),
    ),
    GoRoute(
  path: '/family/:familyId',
  builder: (context, state) {
    final familyId =
        state.pathParameters['familyId']!;

    return FamilyPage(
      familyId: familyId,
    );
  },
),
GoRoute(
  path: '/family/:familyId/add-children',
  builder: (context, state) {
    final familyId =
        state.pathParameters['familyId']!;

    return AddChildrenPage(
      familyId: familyId,
    );
  },
),
GoRoute(
  path: '/child/:childId',
  builder: (context, state) {
    final childId =
        state.pathParameters['childId']!;

    return ChildProfilePage(
      childId: childId,
    );
  },
),
GoRoute(
  path:
      '/family/:familyId/child/:childId/add-milestone',
  builder: (context, state) {
    final familyId =
        state.pathParameters[
            'familyId']!;

    final childId =
        state.pathParameters[
            'childId']!;

    return AddMilestonePage(
      familyId: familyId,
      childId: childId,
    );
  },
),
GoRoute(
  path:
      '/family/:familyId/child/:childId/add-photo',
  builder: (context, state) {
    final familyId =
        state.pathParameters[
            'familyId']!;

    final childId =
        state.pathParameters[
            'childId']!;

    return AddPhotoPage(
      familyId: familyId,
      childId: childId,
    );
  },
),
GoRoute(
  path: '/family/:familyId/calendar',
  builder: (context, state) {
    final familyId =
        state.pathParameters[
            'familyId']!;

    return FamilyCalendarPage(
      familyId: familyId,
    );
  },
),
GoRoute(
  path:
      '/family/:familyId/calendar/add-event',
  builder: (context, state) {
    final familyId =
        state.pathParameters['familyId']!;

    final childId = state.uri.queryParameters['childId'];    

    return AddEventPage(
      familyId: familyId,
      childId: childId,
    );
  },
),
GoRoute(
  path:
      '/family/:familyId/child/:childId/add-document',

  builder: (context, state) {
    final familyId =
        state.pathParameters[
            'familyId']!;

    final childId =
        state.pathParameters[
            'childId']!;

    return AddDocumentPage(
      familyId:
          familyId,
      childId:
          childId,
    );
  },
),
GoRoute(
  path: '/welcome',
  builder: (context, state) =>
      const IntroductionPage(),
),
GoRoute(
  path: '/splash',

  builder: (context, state) =>
      const SplashPage(),
),
GoRoute(
  path: '/families',
  builder: (context, state) =>
      const FamiliesPage(),
),
  ],
);