import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sign_in.dart';
import 'family_dashboard.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});


  @override
  Widget build(BuildContext context) {

    final session =
        Supabase.instance.client.auth.currentSession;


    if (session != null) {

      return const FamilyPage();

    } else {

      return const SignInPage();

    }

  }
}