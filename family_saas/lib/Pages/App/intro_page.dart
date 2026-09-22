import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../Styling/folktri_colors.dart';

class IntroductionPage extends StatelessWidget {
  const IntroductionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FolktriColors.background,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),

                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 440,
                    ),

                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),

                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        crossAxisAlignment:
                            CrossAxisAlignment.center,

                        children: [

                          // =========================
                          // FOLKTRI BRANDING
                          // =========================

                          Image.asset(
                            'assets/images/Folktri_Icon_Indigo.png',

                            width: 90,
                            height: 100,

                            fit: BoxFit.contain,
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Folktri',

                            style: TextStyle(
                              fontSize: 38,

                              fontWeight: FontWeight.bold,

                              letterSpacing: -1.5,

                              color:
                                  FolktriColors.midnightIndigo,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Family closer, every day.',

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: 15,

                              color:
                                  FolktriColors.secondaryText,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // =========================
                          // FAMILY ILLUSTRATION
                          // =========================

                          Container(
                            width: double.infinity,

                            height: 220,

                            decoration: BoxDecoration(
                              color:
                                  FolktriColors.lightLavender,

                              borderRadius:
                                  BorderRadius.circular(28),
                            ),

                            child: Stack(
                              alignment: Alignment.center,

                              children: [

                                Positioned(
                                  top: 22,
                                  left: 24,

                                  child: Icon(
                                    Icons.favorite_rounded,

                                    color:
                                        FolktriColors.dustyRose,

                                    size: 25,
                                  ),
                                ),

                                Positioned(
                                  top: 35,
                                  right: 28,

                                  child: Icon(
                                    Icons.auto_awesome_rounded,

                                    color:
                                        FolktriColors.primaryIndigo,

                                    size: 24,
                                  ),
                                ),

                                const Icon(
                                  Icons.family_restroom_rounded,

                                  size: 125,

                                  color:
                                      FolktriColors.primaryIndigo,
                                ),

                                Positioned(
                                  bottom: 22,

                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),

                                    decoration: BoxDecoration(
                                      color:
                                          FolktriColors.surface,

                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),

                                    child: const Row(
                                      mainAxisSize:
                                          MainAxisSize.min,

                                      children: [

                                        Icon(
                                          Icons.lock_outline_rounded,

                                          color:
                                              FolktriColors.primaryIndigo,

                                          size: 16,
                                        ),

                                        SizedBox(width: 6),

                                        Text(
                                          'Your private family space',

                                          style: TextStyle(
                                            fontSize: 12,

                                            fontWeight:
                                                FontWeight.w500,

                                            color:
                                                FolktriColors.midnightIndigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // =========================
                          // INTRODUCTION TEXT
                          // =========================

                          const Text(
                            'Your family, your world.',

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: 27,

                              fontWeight: FontWeight.bold,

                              color:
                                  FolktriColors.midnightIndigo,

                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            'A private space to share memories, '
                            'celebrate milestones, and stay '
                            'connected with the people who '
                            'matter most.',

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: 15,

                              height: 1.6,

                              color:
                                  FolktriColors.secondaryText,
                            ),
                          ),

                          const SizedBox(height: 34),

                          // =========================
                          // CREATE ACCOUNT BUTTON
                          // =========================

                          SizedBox(
                            width: double.infinity,

                            height: 54,

                            child: ElevatedButton(
                              onPressed: () {
                                context.go('/register');
                              },

                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    FolktriColors.primaryIndigo,

                                foregroundColor:
                                    FolktriColors.surface,

                                elevation: 0,

                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),

                              child: const Text(
                                'Get Started',

                                style: TextStyle(
                                  fontSize: 16,

                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // =========================
                          // SIGN IN BUTTON
                          // =========================

                          SizedBox(
                            width: double.infinity,

                            height: 54,

                            child: OutlinedButton(
                              onPressed: () {
                                context.go('/login');
                              },

                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    FolktriColors.primaryIndigo,

                                side: const BorderSide(
                                  color:
                                      FolktriColors.primaryIndigo,

                                  width: 1.5,
                                ),

                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),

                              child: const Text(
                                'Sign In',

                                style: TextStyle(
                                  fontSize: 16,

                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // =========================
                          // PRIVACY MESSAGE
                          // =========================

                          const Text(
                            'Your memories. Your family. '
                            'Your private space.',

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: 12,

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
          },
        ),
      ),
    );
  }
}