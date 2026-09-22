import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Pages/Styling/folktri_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _animationController;

  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    debugPrint('SPLASH: Timer started');
    // Allow the splash animation to play.
    await Future.delayed(
      const Duration(milliseconds: 2200),
    );

    debugPrint('SPLASH: Timer completed');

    if (!mounted) {
      debugPrint('SPLASH: Widget is no longer mounted');
      return;
    }
 

    final session =
        Supabase.instance.client.auth.currentSession;

    // if (session != null) {
    //   context.go('/app');
    // } else {
    //   context.go('/welcome');
    // }

    final destination =
      session == null ? '/welcome' : '/app';

  debugPrint('SPLASH: Going to $destination');

  try {
    context.go(destination);

    debugPrint('SPLASH: Navigation requested');
  } catch (e, stackTrace) {
    debugPrint('SPLASH ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FolktriColors.surface,

      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,

            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
              ),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  // ==========================
                  // FOLKTRI TREE SYMBOL
                  // ==========================

                  Image.asset(
                    'assets/images/Folktri_Icon_Indigo.png',

                    width: 230,
                    height: 260,

                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 20),

                  // ==========================
                  // FOLKTRI WORDMARK
                  // ==========================

                  const Text(
                    'Folktri',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 52,

                      fontWeight: FontWeight.bold,

                      letterSpacing: -2,

                      color:
                          FolktriColors.midnightIndigo,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Family closer, every day.',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 16,

                      color:
                          FolktriColors.secondaryText,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // ==========================
                  // LOADING INDICATOR
                  // ==========================

                  const SizedBox(
                    width: 160,

                    child: LinearProgressIndicator(
                      minHeight: 4,

                      backgroundColor:
                          FolktriColors.lightLavender,

                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        FolktriColors.primaryIndigo,
                      ),

                      borderRadius:
                          BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'BUILDING BRIGHTER\n'
                    'TOMORROWS TOGETHER',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 11,

                      letterSpacing: 3,

                      height: 1.8,

                      fontWeight: FontWeight.w500,

                      color:
                          FolktriColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}