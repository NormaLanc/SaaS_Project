import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../Services/auth_service.dart';
import '../Pages/Styling/folktri_colors.dart'; // Adjust to your actual path.

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Keep all fields required for your database.
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Create the Supabase Auth account.
      final response = await authService.signUp(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      final user = response.user;

      if (user == null) {
        throw Exception(
          'Unable to create your account. Please try again.',
        );
      }

      // 2. Create the profile using your existing database fields.
      await authService.createProfile(
        userId: user.id,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
      );

      // 3. Preserve your existing sign-out flow.
      await authService.signOut();

      if (!mounted) return;

      // 4. Navigate to the Sign In page.
      context.go('/login');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created! Please sign in to continue.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('REGISTRATION ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to create account: $e',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: FolktriColors.midnightIndigo,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder outline(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: color,
          width: width,
        ),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: FolktriColors.secondaryText,
        fontSize: 15,
      ),
      prefixIcon: Icon(
        icon,
        color: FolktriColors.midnightIndigo,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: FolktriColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      border: outline(
        FolktriColors.lightLavender,
        1.2,
      ),
      enabledBorder: outline(
        FolktriColors.lightLavender,
        1.2,
      ),
      focusedBorder: outline(
        FolktriColors.primaryIndigo,
        1.7,
      ),
      errorBorder: outline(
        FolktriColors.dustyRose,
        1.2,
      ),
      focusedErrorBorder: outline(
        FolktriColors.dustyRose,
        1.7,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FolktriColors.background,

      body: SafeArea(
        child: Stack(
          children: [
            // Soft lavender decorations matching your Sign In page.
            Positioned(
              left: -65,
              bottom: -110,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  color: FolktriColors.lightLavender,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              right: -85,
              bottom: -145,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: FolktriColors.lightLavender
                      .withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 20,
              ),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                  ),

                  child: Form(
                    key: _formKey,

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,

                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/login');
                                    }
                                  },
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: FolktriColors.midnightIndigo,
                              size: 20,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Folktri tree logo
                        Image.asset(
                          'assets/images/Folktri_Icon_Indigo.png',
                          height: 78,
                          fit: BoxFit.contain,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons.park_rounded,
                              size: 70,
                              color: FolktriColors.midnightIndigo,
                            );
                          },
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Folktri',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.5,
                            color: FolktriColors.midnightIndigo,
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Create your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            color: FolktriColors.primaryText,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'A safer, more meaningful way\n'
                          'to keep your family close.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: FolktriColors.secondaryText,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // First name
                        TextFormField(
                          controller: firstNameController,
                          textCapitalization:
                              TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.givenName,
                          ],
                          decoration: _inputDecoration(
                            hint: 'First name',
                            icon: Icons.person_outline_rounded,
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter your first name.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Last name
                        TextFormField(
                          controller: lastNameController,
                          textCapitalization:
                              TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.familyName,
                          ],
                          decoration: _inputDecoration(
                            hint: 'Last name',
                            icon: Icons.person_outline_rounded,
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter your last name.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Phone number
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.telephoneNumber,
                          ],
                          decoration: _inputDecoration(
                            hint: 'Phone number',
                            icon: Icons.phone_outlined,
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter your phone number.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Email
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.email,
                          ],
                          decoration: _inputDecoration(
                            hint: 'Email',
                            icon: Icons.mail_outline_rounded,
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'Please enter your email.';
                            }

                            if (!email.contains('@') ||
                                !email.contains('.')) {
                              return 'Please enter a valid email.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Password
                        TextFormField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [
                            AutofillHints.newPassword,
                          ],
                          onFieldSubmitted: (_) {
                            if (!_isLoading) register();
                          },
                          decoration: _inputDecoration(
                            hint: 'Password',
                            icon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: FolktriColors.secondaryText,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password.';
                            }

                            if (value.length < 8) {
                              return 'Use at least 8 characters.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            'Use at least 8 characters.',
                            style: TextStyle(
                              fontSize: 12,
                              color: FolktriColors.secondaryText,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Create Account button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  FolktriColors.primaryIndigo,
                              foregroundColor:
                                  FolktriColors.surface,
                              disabledBackgroundColor:
                                  FolktriColors.lightLavender,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: FolktriColors.surface,
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sign In link
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Flexible(
                              child: Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color:
                                      FolktriColors.secondaryText,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      context.go('/login');
                                    },
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color:
                                      FolktriColors.primaryIndigo,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import '../Services/auth_service.dart';
// import 'package:go_router/go_router.dart';

// class RegisterPage extends StatefulWidget {
//   const RegisterPage({super.key});


//   @override
//   State<RegisterPage> createState() => _RegisterPageState();
// }


// class _RegisterPageState extends State<RegisterPage> {

//   final firstNameController = TextEditingController();
//   final lastNameController = TextEditingController();
//   final phoneController = TextEditingController();

//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();

//   final authService = AuthService();

// void register() async {

//     try {

//       final response = await authService.signUp(
//         emailController.text.trim(),
//         passwordController.text.trim(),
//       );


//       final user = response.user;


//       if (user != null) {

//         await authService.createProfile(
//           userId: user.id,
//           firstName: firstNameController.text.trim(),
//           lastName: lastNameController.text.trim(),
//           phoneNumber: phoneController.text.trim(),
//         );

//       }


//       if (!mounted) return;

// ScaffoldMessenger.of(context).showSnackBar(
//   const SnackBar(
//     content: Text(
//       "Account Successfully Created!",
//     ),
//   ),
// );
//     await authService.signOut();
//     context.go('/login');


//     } catch(e) {

//       debugPrint('REGISTRATION ERROR: $e');

//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Unable to create account: $e',
//         ),
//       ),
//     );
//     }
//   }
//   // void register() async {

//   //   try {

//   //     await authService.signUp(
//   //       emailController.text.trim(),
//   //       passwordController.text.trim(),
//   //     );


//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text("Account created!"),
//   //       ),
//   //     );


//   //   } catch(e){

//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(
//   //         content: Text(e.toString()),
//   //       ),
//   //     );

//   //   }

//   // }


//   @override
//   Widget build(BuildContext context){

//     return Scaffold(
//     //TODO: Update UI for this page.
//       appBar: AppBar(
//         title: const Text("Create Family Account"),
//       ),


//       body: Padding(

//         padding: const EdgeInsets.all(20),

//         child: Column(

//           children: [

//             TextField(
//               controller: firstNameController,
//               decoration: const InputDecoration(
//               labelText: "First Name",
//             ),
//           ),

//             TextField(
//               controller: lastNameController,
//               decoration: const InputDecoration(
//               labelText: "Last Name",
//             ),
//           ),

//             TextField(
//               controller: phoneController,
//               keyboardType: TextInputType.phone,
//               decoration: const InputDecoration(
//               labelText: "Phone Number",
//             ),
//           ),

//             TextField(
//               controller: emailController,
//               decoration: const InputDecoration(
//                 labelText: "Email",
//               ),
//             ),


//             TextField(
//               controller: passwordController,
//               obscureText: true,
//               decoration: const InputDecoration(
//                 labelText: "Password",
//               ),
//             ),


//             ElevatedButton(
//               onPressed: register,
//               child: const Text("Create Account"),
//             )

//           ],
//         ),
//       ),
//     );
//   }
// }