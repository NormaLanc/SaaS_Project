//This is the landing page for the Folktri Website

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DesktopLandingPage extends StatefulWidget {
  const DesktopLandingPage({super.key});

  @override
  State<DesktopLandingPage> createState() => _DesktopLandingPageState();
}

class _DesktopLandingPageState extends State<DesktopLandingPage> {
  final TextEditingController _emailController =
      TextEditingController();

  bool _isSubmitting = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _joinWaitlist() async {
    final email = _emailController.text.trim();

    // Make sure something was entered
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address.';
      });
      return;
    }

    // Basic email check
    final emailPattern =
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client
          .from('waitlist')
          .insert({
        'email': email,
      });

      if (!mounted) return;

      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });

      _emailController.clear();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // LOGO
                Image.asset(
                  'assets/images/Folktri_hor_logo.png',
                  width: 220,
                ),

                const SizedBox(height: 48),

                // HEADLINE
                const Text(
                  'Private moments belong with family.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                // DESCRIPTION
                const Text(
                  'Folktri is a private space for families '
                  'to stay connected and share the moments '
                  'that matter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 40),

                // EMAIL
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => _joinWaitlist(),
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _isSubmitting ? null : _joinWaitlist,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Notify Me',
                            style: TextStyle(fontSize: 17),
                          ),
                  ),
                ),

                // ERROR
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],

                // SUCCESS
                if (_submitted) ...[
                  const SizedBox(height: 20),
                  const Text(
                    '✓ You’re on the list! We’ll let you know when Folktri launches.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                const Text(
                  'No spam. Just Folktri launch updates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';

// class DesktopLandingPage extends StatelessWidget {
//   const DesktopLandingPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           // WebNavigationBar(),
//           // HeroSection(),
//           // FeaturesSection(),
//           // SecuritySection(),
//           // PricingSection(),
//           // FooterSection(),
//         ],
//       ),
//     );
//   }
// }