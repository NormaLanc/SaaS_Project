import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../website_navbar.dart';

class PoliciesPage extends StatelessWidget {
  const PoliciesPage({super.key});

  static const Color folktriPurple = Color(0xFF7652A8);
  static const Color folktriDark = Color(0xFF17152E);
  static const Color folktriText = Color(0xFF565365);
  static const Color folktriBackground = Color(0xFFFFFBFF);
  static const Color folktriLightPurple = Color(0xFFF3EEFA);
  static const Color folktriSoftPurple = Color(0xFFE9DDF7);
  static const Color folktriBorder = Color(0xFFECE7F2);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: folktriBackground,
      body: Column(
        children: [
          const WebsiteNavbar(),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHero(isMobile),
                  _buildPolicySection(context, isMobile),
                  _buildCommitmentSection(isMobile),
                  _buildFooter(context, isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // HERO
  // ----------------------------------------------------------

  Widget _buildHero(bool isMobile) {
    return Container(
      width: double.infinity,
      color: folktriLightPurple,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 70 : 100,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: folktriPurple,
                  size: 34,
                ),
              ),

              const SizedBox(height: 26),

              const Text(
                'FOLKTRI POLICIES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriPurple,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Privacy and transparency\n'
                'matter to us.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriDark,
                  fontSize: isMobile ? 39 : 56,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Folktri is designed around private family '
                'spaces. Our policies explain how Folktri '
                'works, how information is handled, and the '
                'rules that apply when using the service.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriText,
                  fontSize: isMobile ? 16 : 18,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // POLICY CARDS
  // ----------------------------------------------------------

  Widget _buildPolicySection(
    BuildContext context,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 70 : 100,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1050,
          ),
          child: Column(
            children: [
              const Text(
                'POLICIES & AGREEMENTS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Learn more about Folktri',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriDark,
                  fontSize: isMobile ? 32 : 42,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Select a policy below to learn more about '
                'your privacy, your responsibilities, and '
                'how Folktri handles family information.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriText,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 50),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return Column(
                      children: [
                        _PolicyCard(
                          icon: Icons.lock_outline_rounded,
                          title: 'Privacy Policy',
                          description:
                              'Learn what information Folktri '
                              'collects, why it is used, and how '
                              'your information is handled.',
                          onTap: () {
                            context.go('/policies/privacy');
                          },
                        ),

                        const SizedBox(height: 18),

                        _PolicyCard(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          description:
                              'Understand the rules and terms '
                              'that apply when creating an '
                              'account and using Folktri.',
                          onTap: () {
                            context.go('/policies/terms');
                          },
                        ),

                        const SizedBox(height: 18),

                        _PolicyCard(
                          icon: Icons.child_care_outlined,
                          title: 'Children’s Privacy',
                          description:
                              'Learn how Folktri approaches '
                              'children, family accounts, and '
                              'privacy involving younger users.',
                          onTap: () {
                            context.go('/policies/children');
                          },
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _PolicyCard(
                          icon: Icons.lock_outline_rounded,
                          title: 'Privacy Policy',
                          description:
                              'Learn what information Folktri '
                              'collects, why it is used, and how '
                              'your information is handled.',
                          onTap: () {
                            context.go('/policies/privacy');
                          },
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: _PolicyCard(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          description:
                              'Understand the rules and terms '
                              'that apply when creating an '
                              'account and using Folktri.',
                          onTap: () {
                            context.go('/policies/terms');
                          },
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: _PolicyCard(
                          icon: Icons.child_care_outlined,
                          title: 'Children’s Privacy',
                          description:
                              'Learn how Folktri approaches '
                              'children, family accounts, and '
                              'privacy involving younger users.',
                          onTap: () {
                            context.go('/policies/children');
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // PRIVACY COMMITMENT
  // ----------------------------------------------------------

  Widget _buildCommitmentSection(bool isMobile) {
    return Container(
      width: double.infinity,
      color: folktriDark,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 70 : 95,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 900,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.family_restroom_outlined,
                color: folktriSoftPurple,
                size: 44,
              ),

              const SizedBox(height: 24),

              Text(
                'Built with family privacy in mind.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 31 : 42,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Families share deeply personal moments and '
                'information. Folktri is being designed to give '
                'families greater control over who participates '
                'in their private family spaces.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFD6D2DF),
                  fontSize: 17,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // FOOTER
  // ----------------------------------------------------------

  Widget _buildFooter(
    BuildContext context,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: 50,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: Column(
            children: [
              const Divider(),

              const SizedBox(height: 30),

              Image.asset(
                'assets/images/Folktri_hor_logo.png',
                width: 120,
              ),

              const SizedBox(height: 24),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 12,
                children: [
                  _FooterLink(
                    label: 'About',
                    onTap: () {
                      context.go('/about');
                    },
                  ),
                  _FooterLink(
                    label: 'Features',
                    onTap: () {
                      context.go('/features');
                    },
                  ),
                  _FooterLink(
                    label: 'Support',
                    onTap: () {
                      context.go('/support');
                    },
                  ),
                  _FooterLink(
                    label: 'Privacy',
                    onTap: () {
                      context.go('/policies/privacy');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                '© 2026 Folktri. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------
// POLICY CARD
// ----------------------------------------------------------

class _PolicyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _PolicyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: PoliciesPage.folktriBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: PoliciesPage.folktriLightPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: PoliciesPage.folktriPurple,
                  size: 27,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                title,
                style: const TextStyle(
                  color: PoliciesPage.folktriDark,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    color: PoliciesPage.folktriText,
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Row(
                children: [
                  Text(
                    'Read policy',
                    style: TextStyle(
                      color: PoliciesPage.folktriPurple,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: PoliciesPage.folktriPurple,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------
// FOOTER LINK
// ----------------------------------------------------------

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: PoliciesPage.folktriText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}