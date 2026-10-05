import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../website_navbar.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  static const Color folktriPurple = Color(0xFF7652A8);
  static const Color folktriDark = Color(0xFF17152E);
  static const Color folktriText = Color(0xFF565365);
  static const Color folktriBackground = Color(0xFFFFFBFF);
  static const Color folktriLightPurple = Color(0xFFF3EEFA);
  static const Color folktriSoftPurple = Color(0xFFE9DDF7);
  static const Color folktriBorder = Color(0xFFECE7F2);

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  final List<_FaqData> _faqs = const [
    _FaqData(
      question: 'What is Folktri?',
      answer:
          'Folktri is a private Family OS designed to help '
          'families stay connected, preserve memories, organize '
          'family life, and share important moments with the '
          'people they trust.',
    ),
    _FaqData(
      question: 'Who can join my family?',
      answer:
          'Family spaces are designed around invitations. '
          'The family owner can invite relatives and other '
          'trusted people to join their family space.',
    ),
    _FaqData(
      question: 'How do family invitations work?',
      answer:
          'A family owner can create an invitation for another '
          'person. Invitations can include a family role and '
          'permissions that help determine what the invited '
          'member can access.',
    ),
    _FaqData(
      question: 'Can someone see my family without being invited?',
      answer:
          'Folktri family spaces are designed around invited '
          'membership rather than public followers. Access to '
          'family content depends on membership and permissions.',
    ),
    _FaqData(
      question: 'What can I share on Folktri?',
      answer:
          'Folktri is designed for family photos, albums, child '
          'milestones, family events, schedules, and other '
          'information families want to keep together.',
    ),
    _FaqData(
      question: 'Can family members have different permissions?',
      answer:
          'Yes. Folktri supports family roles and permissions so '
          'access can be managed based on the needs of each '
          'family.',
    ),
    _FaqData(
      question: 'How do I delete my account?',
      answer:
          'Account management options are available from within '
          'Folktri settings. Additional account assistance can '
          'also be requested through Folktri support.',
    ),
    _FaqData(
      question: 'Where can I read the Privacy Policy?',
      answer:
          'Folktri privacy information is available from the '
          'Policies section of the website.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqData> get _filteredFaqs {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _faqs;
    }

    return _faqs.where((faq) {
      return faq.question.toLowerCase().contains(query) ||
          faq.answer.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _contactSupport() async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: 'customer_support@folktri.com',
    queryParameters: {
      'subject': 'Folktri Customer Support',
    },
  );

  if (!await launchUrl(emailUri)) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to open your email app. '
          'Please email customer_support@folktri.com.',
        ),
      ),
    );
  }
}

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
                  _buildHelpCategories(isMobile),
                  _buildFaqSection(isMobile),
                  _buildContactSection(isMobile),
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
      color: folktriLightPurple,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 65 : 90,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ),
          child: Column(
            children: [
              const Text(
                'FOLKTRI SUPPORT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriPurple,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'How can we help?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriDark,
                  fontSize: isMobile ? 40 : 58,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Find answers about Folktri, family spaces, '
                'privacy, account settings, and more.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriText,
                  fontSize: isMobile ? 16 : 18,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 38),

              Container(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search Folktri help...',
                    hintStyle: const TextStyle(
                      color: Colors.black38,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: folktriPurple,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(
                              Icons.close_rounded,
                            ),
                            onPressed: () {
                              _searchController.clear();

                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
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
  // HELP CATEGORIES
  // ----------------------------------------------------------

  Widget _buildHelpCategories(bool isMobile) {
    const categories = [
      _SupportCategory(
        icon: Icons.rocket_launch_outlined,
        title: 'Getting Started',
        description:
            'Learn the basics of creating an account and '
            'getting started with Folktri.',
      ),
      _SupportCategory(
        icon: Icons.family_restroom_outlined,
        title: 'Family & Invitations',
        description:
            'Learn about family spaces, invitations, roles, '
            'and member permissions.',
      ),
      _SupportCategory(
        icon: Icons.shield_outlined,
        title: 'Privacy & Safety',
        description:
            'Understand how privacy, family access, and '
            'account safety work in Folktri.',
      ),
      _SupportCategory(
        icon: Icons.settings_outlined,
        title: 'Account & Settings',
        description:
            'Get help with your profile, account settings, '
            'notifications, and account management.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 70 : 95,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: Column(
            children: [
              const Text(
                'HELP CENTER',
                style: TextStyle(
                  color: folktriPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Browse help by topic',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriDark,
                  fontSize: isMobile ? 32 : 42,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 50),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 750) {
                    return Column(
                      children: categories
                          .map(
                            (category) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: 18,
                              ),
                              child: _CategoryCard(
                                category: category,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }

                  return Wrap(
                    spacing: 22,
                    runSpacing: 22,
                    children: categories
                        .map(
                          (category) => SizedBox(
                            width:
                                (constraints.maxWidth - 22) / 2,
                            child: _CategoryCard(
                              category: category,
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
  // FAQ
  // ----------------------------------------------------------

  Widget _buildFaqSection(bool isMobile) {
    final filteredFaqs = _filteredFaqs;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 70 : 100,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 850,
          ),
          child: Column(
            children: [
              const Text(
                'FREQUENTLY ASKED QUESTIONS',
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
                'Quick answers to common questions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriDark,
                  fontSize: isMobile ? 31 : 42,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 45),

              if (filteredFaqs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(35),
                  decoration: BoxDecoration(
                    color: folktriLightPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        color: folktriPurple,
                        size: 36,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'No help articles matched your search.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: folktriDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filteredFaqs.map(
                  (faq) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 12),
                    child: _FaqTile(
                      faq: faq,
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
  // CONTACT SUPPORT
  // ----------------------------------------------------------

  Widget _buildContactSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 48,
        vertical: isMobile ? 65 : 90,
      ),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 60,
            vertical: isMobile ? 50 : 65,
          ),
          decoration: BoxDecoration(
            color: folktriSoftPurple,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: folktriPurple,
                  size: 29,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Still need help?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriDark,
                  fontSize: isMobile ? 30 : 38,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'If you cannot find the answer you need, '
                'you can contact Folktri Support for additional '
                'assistance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: folktriText,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 28),

              OutlinedButton.icon(
                onPressed: _contactSupport,
                icon: const Icon(
                  Icons.mail_outline_rounded,
                ),
                label: const Text(
                  'Contact Support',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'customer_support@folktri.com',
                style: TextStyle(
                  color: folktriText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
// SUPPORT CATEGORY DATA
// ----------------------------------------------------------

class _SupportCategory {
  final IconData icon;
  final String title;
  final String description;

  const _SupportCategory({
    required this.icon,
    required this.title,
    required this.description,
  });
}

// ----------------------------------------------------------
// CATEGORY CARD
// ----------------------------------------------------------

class _CategoryCard extends StatelessWidget {
  final _SupportCategory category;

  const _CategoryCard({
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 190,
      ),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _SupportPageState.folktriBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _SupportPageState.folktriLightPurple,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              category.icon,
              color: _SupportPageState.folktriPurple,
              size: 26,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            category.title,
            style: const TextStyle(
              color: _SupportPageState.folktriDark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            category.description,
            style: const TextStyle(
              color: _SupportPageState.folktriText,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------
// FAQ DATA
// ----------------------------------------------------------

class _FaqData {
  final String question;
  final String answer;

  const _FaqData({
    required this.question,
    required this.answer,
  });
}

// ----------------------------------------------------------
// FAQ TILE
// ----------------------------------------------------------

class _FaqTile extends StatelessWidget {
  final _FaqData faq;

  const _FaqTile({
    required this.faq,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _SupportPageState.folktriBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _SupportPageState.folktriBorder,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 8,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            22,
            0,
            22,
            22,
          ),
          iconColor: _SupportPageState.folktriPurple,
          collapsedIconColor:
              _SupportPageState.folktriPurple,
          title: Text(
            faq.question,
            style: const TextStyle(
              color: _SupportPageState.folktriDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq.answer,
                style: const TextStyle(
                  color: _SupportPageState.folktriText,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}