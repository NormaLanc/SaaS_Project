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
    required DateTime dateOfBirth,
  }) async {

    await supabase
        .from('Profiles')
        .insert({

      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'date_of_birth':  
      '${dateOfBirth.year.toString().padLeft(4, '0')}-'
        '${dateOfBirth.month.toString().padLeft(2, '0')}-'
        '${dateOfBirth.day.toString().padLeft(2, '0')}',

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