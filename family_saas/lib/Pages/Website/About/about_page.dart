import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../website_navbar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const Color folktriPurple = Color(0xFF7652A8);
  static const Color folktriLightPurple = Color(0xFFF3EEFA);
  static const Color folktriSoftPurple = Color(0xFFE9DDF7);
  static const Color folktriDark = Color(0xFF17152E);
  static const Color folktriText = Color(0xFF565365);
  static const Color folktriBackground = Color(0xFFFFFBFF);

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
                  // HERO
                  _buildHero(context, isMobile),

                  // THE PROBLEM
                  _buildProblemSection(isMobile),

                  // WHAT FOLKTRI OFFERS
                  _buildBenefitsSection(isMobile),

                  // FOOTER
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

  Widget _buildHero(
    BuildContext context,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 70 : 105,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 900,
          ),
          child: Column(
            children: [
              const Text(
                'WELCOME TO FOLKTRI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriPurple,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'A private space for\n'
                'your family’s journey.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriDark,
                  fontSize: isMobile ? 42 : 64,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.5,
                ),
              ),

              const SizedBox(height: 28),

              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 680,
                ),
                child: const Text(
  'Folktri is a private Family OS designed to give families '
  'one place to stay connected, preserve memories, organize '
  'family life, and share the moments that matter with the '
  'people they trust.',
  textAlign: TextAlign.center,
  style: TextStyle(
    color: folktriText,
    fontSize: 19,
    height: 1.6,
  ),
),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // PROBLEM
  // ----------------------------------------------------------

  Widget _buildProblemSection(bool isMobile) {
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
            maxWidth: 1050,
          ),
          child: isMobile
              ? Column(
                  children: [
                    _problemHeading(isMobile),
                    const SizedBox(height: 40),
                    _problemCard(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _problemHeading(isMobile),
                    ),
                    const SizedBox(width: 80),
                    Expanded(
                      child: _problemCard(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _problemHeading(bool isMobile) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        const Text(
          'WHY FOLKTRI?',
          style: TextStyle(
            color: folktriPurple,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 18),

        Text(
          'Family sharing deserves '
          'a space built for family.',
          textAlign:
              isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: folktriDark,
            fontSize: isMobile ? 34 : 44,
            height: 1.15,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Public social media was not designed around '
          'the privacy of family life. Parents often have '
          'to choose between sharing important moments '
          'online or leaving distant loved ones out of '
          'everyday memories.',
          textAlign:
              isMobile ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            color: folktriText,
            fontSize: 17,
            height: 1.7,
          ),
        ),

        const SizedBox(height: 18),

        Text(
          'Folktri creates another option: a private '
          'family space where the people you choose can '
          'stay connected.',
          textAlign:
              isMobile ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            color: folktriText,
            fontSize: 17,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _problemCard() {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProblemItem(
            icon: Icons.public_off_outlined,
            title: 'Less public sharing',
            description:
                'Your family moments do not need to become '
                'content for the entire internet.',
          ),

          SizedBox(height: 30),

          _ProblemItem(
            icon: Icons.family_restroom_outlined,
            title: 'More meaningful connection',
            description:
                'Give grandparents, relatives, and trusted '
                'loved ones a dedicated way to stay involved.',
          ),

          SizedBox(height: 30),

          _ProblemItem(
            icon: Icons.lock_outline,
            title: 'You choose who belongs',
            description:
                'Folktri is designed around invited family '
                'spaces rather than public followers.',
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // BENEFITS
  // ----------------------------------------------------------

  Widget _buildBenefitsSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 80 : 110,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: Column(
            children: [
              const Text(
                'BUILT AROUND FAMILY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Everything your family needs,\n'
                'in one private place.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriDark,
                  fontSize: isMobile ? 34 : 46,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Folktri brings connection, memories, and '
                'family organization together without the '
                'noise of traditional social media.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriText,
                  fontSize: 17,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 60),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 750) {
                    return const Column(
                      children: [
                        _BenefitCard(
                          icon: Icons.lock_outline_rounded,
                          title: 'Privacy',
                          description:
                              'Share with invited family '
                              'instead of public followers.',
                        ),
                        SizedBox(height: 18),
                        _BenefitCard(
                          icon: Icons.photo_library_outlined,
                          title: 'Memories',
                          description:
                              'Keep photos, milestones, and '
                              'meaningful moments together.',
                        ),
                        SizedBox(height: 18),
                        _BenefitCard(
                          icon: Icons.calendar_month_outlined,
                          title: 'Organization',
                          description:
                              'Keep up with schedules, events, '
                              'and the things your family needs.',
                        ),
                        SizedBox(height: 18),
                        _BenefitCard(
                          icon: Icons.favorite_border_rounded,
                          title: 'Connection',
                          description:
                              'Help loved ones stay involved '
                              'even when they live far away.',
                        ),
                      ],
                    );
                  }

                  return const Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _BenefitCard(
                              icon: Icons.lock_outline_rounded,
                              title: 'Privacy',
                              description:
                                  'Share with invited family '
                                  'instead of public followers.',
                            ),
                          ),
                          SizedBox(width: 22),
                          Expanded(
                            child: _BenefitCard(
                              icon:
                                  Icons.photo_library_outlined,
                              title: 'Memories',
                              description:
                                  'Keep photos, milestones, '
                                  'and meaningful moments '
                                  'together.',
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: _BenefitCard(
                              icon:
                                  Icons.calendar_month_outlined,
                              title: 'Organization',
                              description:
                                  'Keep up with schedules, '
                                  'events, and the things your '
                                  'family needs.',
                            ),
                          ),
                          SizedBox(width: 22),
                          Expanded(
                            child: _BenefitCard(
                              icon:
                                  Icons.favorite_border_rounded,
                              title: 'Connection',
                              description:
                                  'Help loved ones stay involved '
                                  'even when they live far away.',
                            ),
                          ),
                        ],
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

  Widget _buildFooter(
  BuildContext context,
  bool isMobile,
) {
  return Padding(
    padding: EdgeInsets.symmetric(
      horizontal: isMobile ? 24 : 48,
      vertical: 50,
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 1100,
      ),
      child: Column(
        children: [
          const Divider(),

          const SizedBox(height: 30),

          isMobile
              ? Column(
                  children: [
                    Image.asset(
                      'assets/images/Folktri_hor_logo.png',
                      width: 120,
                    ),
                    const SizedBox(height: 24),
                    _footerLinks(context),
                  ],
                )
              : Row(
                  children: [
                    Image.asset(
                      'assets/images/Folktri_hor_logo.png',
                      width: 120,
                    ),
                    const Spacer(),
                    _footerLinks(context),
                  ],
                ),

          const SizedBox(height: 30),

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
  );
}

  Widget _footerLinks(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 12,
      children: [
        _FooterLink(
          label: 'About',
          onTap: () => context.go('/about'),
        ),
        _FooterLink(
          label: 'Support',
          onTap: () => context.go('/support'),
        ),
        _FooterLink(
          label: 'Privacy',
          onTap: () => context.go('/policies'),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------
// PROBLEM ITEM
// ----------------------------------------------------------

class _ProblemItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ProblemItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AboutPage.folktriLightPurple,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: AboutPage.folktriPurple,
          ),
        ),

        const SizedBox(width: 18),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AboutPage.folktriDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  color: AboutPage.folktriText,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------
// BENEFIT CARD
// ----------------------------------------------------------

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 210,
      ),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFECE7F2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AboutPage.folktriLightPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: AboutPage.folktriPurple,
              size: 27,
            ),
          ),

          const SizedBox(height: 22),

          Text(
            title,
            style: const TextStyle(
              color: AboutPage.folktriDark,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            description,
            style: const TextStyle(
              color: AboutPage.folktriText,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
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
            color: AboutPage.folktriText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}