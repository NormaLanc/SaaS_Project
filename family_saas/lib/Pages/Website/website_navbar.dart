import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WebsiteNavbar extends StatelessWidget {
  const WebsiteNavbar({super.key});

  static const Color folktriPurple = Color(0xFF7652A8);
  static const Color folktriDark = Color(0xFF17152E);
  static const Color folktriBackground = Color(0xFFFFFBFF);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 850;

    return Container(
      height: 82,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 48,
      ),
      color: folktriBackground,
      child: Row(
        children: [
          // FOLKTRI LOGO
          InkWell(
            onTap: () => context.go('/'),
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/Folktri_hor_logo.png',
              width: isMobile ? 125 : 145,
            ),
          ),

          const Spacer(),

          // DESKTOP NAVIGATION
          if (!isMobile) ...[
            _NavItem(
              label: 'Home',
              onTap: () => context.go('/'),
            ),
            _NavItem(
              label: 'About',
              onTap: () => context.go('/about'),
            ),
            _NavItem(
              label: 'Features',
              onTap: () => context.go('/features'),
            ),
            _NavItem(
              label: 'Support',
              onTap: () => context.go('/support'),
            ),
            _NavItem(
              label: 'Policies',
              onTap: () => context.go('/policies'),
            ),

            const SizedBox(width: 20),

            ElevatedButton(
              onPressed: () {
                // We will connect this to the waitlist section
                // in the next step.
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: folktriPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 17,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Join the Waitlist',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // MOBILE NAVIGATION
          if (isMobile)
            IconButton(
              tooltip: 'Menu',
              icon: const Icon(
                Icons.menu_rounded,
                size: 30,
                color: folktriDark,
              ),
              onPressed: () => _showMobileMenu(context),
            ),
        ],
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: folktriBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              18,
              24,
              32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/Folktri_hor_logo.png',
                      width: 125,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _MobileNavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/');
                  },
                ),

                _MobileNavItem(
                  icon: Icons.favorite_border,
                  label: 'About',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/about');
                  },
                ),

                _MobileNavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Features',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/features');
                  },
                ),

                _MobileNavItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Support',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/support');
                  },
                ),

                _MobileNavItem(
                  icon: Icons.description_outlined,
                  label: 'Policies',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/policies');
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.go('/');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: folktriPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 17,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Join the Waitlist',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 10,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: WebsiteNavbar.folktriDark,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MobileNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ),
      leading: Icon(
        icon,
        color: WebsiteNavbar.folktriPurple,
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: WebsiteNavbar.folktriDark,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
      ),
    );
  }
}