import 'package:flutter/material.dart';

import '../website_navbar.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

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
                  _buildFeatureGrid(isMobile),
                  _buildPrivateFamilySection(isMobile),
                  _buildOrganizationSection(isMobile),
                  _buildFooter(isMobile),
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
                'FOLKTRI FEATURES',
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
                'Everything your family needs,\n'
                'in one private place.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriDark,
                  fontSize: isMobile ? 40 : 62,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.5,
                ),
              ),

              const SizedBox(height: 28),

              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 700,
                ),
                child: Text(
                  'Folktri brings family memories, schedules, '
                  'important information, and the people you love '
                  'together in a space designed around family.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: folktriText,
                    fontSize: isMobile ? 17 : 19,
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
  // FEATURE GRID
  // ----------------------------------------------------------

  Widget _buildFeatureGrid(bool isMobile) {
    const features = [
      _FeatureData(
        icon: Icons.family_restroom_rounded,
        title: 'Private Family Spaces',
        description:
            'Create a space for your household and invite the '
            'family members and trusted people you choose.',
      ),
      _FeatureData(
        icon: Icons.photo_library_outlined,
        title: 'Photos & Albums',
        description:
            'Share family photos privately and organize '
            'memories into albums your family can revisit.',
      ),
      _FeatureData(
        icon: Icons.auto_awesome_outlined,
        title: 'Milestones',
        description:
            'Capture important moments in your child’s life '
            'with dates, descriptions, and photos.',
      ),
      _FeatureData(
        icon: Icons.child_care_outlined,
        title: 'Child Profiles',
        description:
            'Give each child their own space for the memories '
            'and information that matter to your family.',
      ),
      _FeatureData(
        icon: Icons.calendar_month_outlined,
        title: 'Family Calendar',
        description:
            'Keep family events, important dates, and schedules '
            'organized in one shared place.',
      ),
      _FeatureData(
        icon: Icons.folder_outlined,
        title: 'Family Documents',
        description:
            'Keep important family and child-related documents '
            'organized alongside the rest of family life.',
      ),
      _FeatureData(
        icon: Icons.manage_accounts_outlined,
        title: 'Invitations & Permissions',
        description:
            'Control who joins your family space and what '
            'different members are allowed to access.',
      ),
      _FeatureData(
        icon: Icons.favorite_border_rounded,
        title: 'Family Connection',
        description:
            'Help grandparents, relatives, and loved ones stay '
            'part of everyday family life from wherever they are.',
      ),
    ];

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
            maxWidth: 1100,
          ),
          child: Column(
            children: [
              const Text(
                'BUILT FOR EVERYDAY FAMILY LIFE',
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
                'One home for the things\n'
                'your family shares.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriDark,
                  fontSize: isMobile ? 34 : 46,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 55),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 750) {
                    return Column(
                      children: features
                          .map(
                            (feature) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 18),
                              child: _FeatureCard(
                                feature: feature,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }

                  return Wrap(
                    spacing: 22,
                    runSpacing: 22,
                    children: features
                        .map(
                          (feature) => SizedBox(
                            width:
                                (constraints.maxWidth - 22) / 2,
                            child: _FeatureCard(
                              feature: feature,
                            ),
                          ),
                        )
                        .toList(),
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
  // PRIVATE FAMILY SECTION
  // ----------------------------------------------------------

  Widget _buildPrivateFamilySection(bool isMobile) {
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
          child: isMobile
              ? Column(
                  children: [
                    _privateFamilyText(true),
                    const SizedBox(height: 45),
                    _privacyVisual(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _privateFamilyText(false),
                    ),
                    const SizedBox(width: 80),
                    Expanded(
                      child: _privacyVisual(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _privateFamilyText(bool isMobile) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        const Text(
          'PRIVATE BY DESIGN',
          style: TextStyle(
            color: folktriPurple,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 18),

        Text(
          'Your family space is\n'
          'for your family.',
          textAlign:
              isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: folktriDark,
            fontSize: isMobile ? 34 : 46,
            height: 1.15,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Folktri is built around invited family spaces. '
          'Instead of sharing your family life with a public '
          'audience, you decide who belongs in your space.',
          textAlign:
              isMobile ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            color: folktriText,
            fontSize: 17,
            height: 1.7,
          ),
        ),

        const SizedBox(height: 26),

        const _CheckItem(
          text: 'Invite family members using private invitations',
        ),
        const _CheckItem(
          text: 'Assign roles within your family',
        ),
        const _CheckItem(
          text: 'Control access with member permissions',
        ),
        const _CheckItem(
          text: 'Keep family sharing separate from public social media',
        ),
      ],
    );
  }

  Widget _privacyVisual() {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: folktriLightPurple,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 42,
              color: folktriPurple,
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Your Family',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: folktriDark,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Parents • Grandparents • Siblings\n'
            'Relatives • Trusted Family',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: folktriText,
              fontSize: 15,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 30),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: const [
              _FamilyBubble(
                icon: Icons.person_outline,
              ),
              _FamilyBubble(
                icon: Icons.person_outline,
              ),
              _FamilyBubble(
                icon: Icons.child_care_outlined,
              ),
              _FamilyBubble(
                icon: Icons.person_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // ORGANIZATION SECTION
  // ----------------------------------------------------------

  Widget _buildOrganizationSection(bool isMobile) {
    return Container(
      width: double.infinity,
      color: folktriDark,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 75 : 100,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.home_outlined,
                color: folktriSoftPurple,
                size: 45,
              ),

              const SizedBox(height: 25),

              Text(
                'More than a place to share photos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 32 : 44,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 22),

              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 720,
                ),
                child: const Text(
                  'Folktri is being built as a Family OS — '
                  'a central place for the memories, people, '
                  'schedules, and information that make up '
                  'everyday family life.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFD6D2DF),
                    fontSize: 17,
                    height: 1.7,
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
  // FOOTER
  // ----------------------------------------------------------

  Widget _buildFooter(bool isMobile) {
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

              const SizedBox(height: 25),

              const Text(
                'Private moments belong with family.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriText,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 25),

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
// FEATURE DATA
// ----------------------------------------------------------

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

// ----------------------------------------------------------
// FEATURE CARD
// ----------------------------------------------------------

class _FeatureCard extends StatelessWidget {
  final _FeatureData feature;

  const _FeatureCard({
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 220,
      ),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: FeaturesPage.folktriBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: FeaturesPage.folktriLightPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              feature.icon,
              color: FeaturesPage.folktriPurple,
              size: 27,
            ),
          ),

          const SizedBox(height: 22),

          Text(
            feature.title,
            style: const TextStyle(
              color: FeaturesPage.folktriDark,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            feature.description,
            style: const TextStyle(
              color: FeaturesPage.folktriText,
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
// CHECK ITEM
// ----------------------------------------------------------

class _CheckItem extends StatelessWidget {
  final String text;

  const _CheckItem({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: FeaturesPage.folktriLightPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: FeaturesPage.folktriPurple,
              size: 16,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: FeaturesPage.folktriText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------
// FAMILY BUBBLE
// ----------------------------------------------------------

class _FamilyBubble extends StatelessWidget {
  final IconData icon;

  const _FamilyBubble({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        color: FeaturesPage.folktriPurple,
      ),
    );
  }
}