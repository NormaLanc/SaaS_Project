import 'package:flutter/material.dart';
import '../Services/auth_service.dart';
//import '../Pages/create_account.dart';
//import '../Pages/App/family_dashboard.dart';
import '../Pages/Styling/folktri_colors.dart';
import 'package:go_router/go_router.dart';


class SignInPage extends StatefulWidget {
  const SignInPage({super.key});


  @override
  State<SignInPage> createState() => _SignInPageState();
}


class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

    @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }


  // void login() async {

  //   try {

  //     await authService.signIn(
  //       emailController.text.trim(),
  //       passwordController.text.trim(),
  //     );

  //     if (!mounted) return;

  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => const FamilyDashboard(),
  //       ),
  //     );
  //     // ScaffoldMessenger.of(context).showSnackBar(
  //     //   const SnackBar(
  //     //     content: Text("Account created!"),
  //     //   ),
  //     // );


  //   } catch(e){
  //     if (!mounted) return;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(e.toString()),
  //       ),
  //     );

  //   }

  // }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await authService.signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;

      context.go('/app');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: FolktriColors.midnightIndigo,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

    InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: FolktriColors.lightLavender,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: FolktriColors.lightLavender,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: FolktriColors.primaryIndigo,
          width: 1.7,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: FolktriColors.dustyRose,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: FolktriColors.dustyRose,
          width: 1.7,
        ),
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
            // Subtle lavender decoration at the bottom.
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
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/welcome');
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: FolktriColors.midnightIndigo,
                              size: 20,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Folktri logo
                        Image.asset(
                          'assets/images/Folktri_Icon_Indigo.png',
                          height: 92,
                          fit: BoxFit.contain,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons.park_rounded,
                              size: 76,
                              color: FolktriColors.midnightIndigo,
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Folktri',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.5,
                            color: FolktriColors.midnightIndigo,
                          ),
                        ),

                        const SizedBox(height: 32),

                        const Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: FolktriColors.primaryText,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Family closer, every day.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: FolktriColors.secondaryText,
                          ),
                        ),

                        const SizedBox(height: 46),

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
                            AutofillHints.password,
                          ],
                          onFieldSubmitted: (_) {
                            if (!_isLoading) login();
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
                              return 'Please enter your password.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 10),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Connect this to your password
                              // recovery page when it is ready.
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password recovery is coming soon.',
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: FolktriColors.primaryIndigo,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sign In button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : login,
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
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Create account link
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Flexible(
                              child: Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  color:
                                      FolktriColors.secondaryText,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.go('/register');
                              },
                              child: const Text(
                                'Create one',
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
  // Widget build(BuildContext context){

  //   return Scaffold(
  //     //TODO: Update UI for this page.
  //     appBar: AppBar(
  //       title: const Text("Sign In"),
  //     ),


  //     body: Padding(

  //       padding: const EdgeInsets.all(20),

  //       child: Column(

  //         children: [

  //           TextField(
  //             controller: emailController,
  //             decoration: const InputDecoration(
  //               labelText: "Email",
  //             ),
  //           ),


  //           TextField(
  //             controller: passwordController,
  //             obscureText: true,
  //             decoration: const InputDecoration(
  //               labelText: "Password",
  //             ),
  //           ),

  //           //Login button
  //           ElevatedButton(
  //             onPressed: login,
  //             child: const Text("Login"),
  //           ),

  //           //Create an account button
  //           TextButton(
  //             onPressed: () {

  //             Navigator.push(
  //               context,
  //             MaterialPageRoute(
  //              builder: (context) => const RegisterPage(),
  //             ),
  //           );

  //         },
  //         child: const Text(
  //           "Create an account",
  //         ),
  //       ),

  //         ],
  //       ),
  //     ),
  //   );
  // }
//}
