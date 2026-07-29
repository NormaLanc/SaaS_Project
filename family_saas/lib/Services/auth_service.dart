import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {

  final SupabaseClient supabase = Supabase.instance.client;


  Future<AuthResponse> signUp(
      String email,
      String password,
  ) async {

    return await supabase.auth.signUp(
      email: email,
      password: password,
    );

  }

  Future<void> createProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {

    await supabase
        .from('profiles')
        .insert({

      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,

    });

  }


  Future<AuthResponse> signIn(

      String email,
      String password,
  ) async {

    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

  }


  Future<void> signOut() async {
    await supabase.auth.signOut();
  }


  User? get currentUser {
    return supabase.auth.currentUser;
  }
}