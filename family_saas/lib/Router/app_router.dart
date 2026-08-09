import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Pages/landing_page.dart';
import '../Pages/sign_in.dart';
import '../Pages/create_account.dart';
import '../Pages/family_dashboard.dart';
import '../Pages/App/family_dashboard.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: kIsWeb ? '/' : '/app',

  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    final path = state.uri.path;

    final isPublicPage =
        path == '/' ||
        path == '/login' ||
        path == '/register';

    if (!isLoggedIn && !isPublicPage) {
      return '/login';
    }

    if (isLoggedIn &&
        (path == '/login' || path == '/register')) {
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
      path: '/family-setup',
      builder: (context, state) => const FamilyPage(),
    ),
    GoRoute(
      path: '/app',
      builder: (context, state) => const FamilyDashboard(),
    ),
  ],
);