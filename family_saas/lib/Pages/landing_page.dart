import 'package:flutter/material.dart';
import 'package:family_saas/Pages/Website/landing_page.dart';
import 'package:family_saas/Pages/App/landing_page.dart';


class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    //final width = MediaQuery.sizeOf(context).width;
    return const DesktopLandingPage();
    // if (width >= 900) {
    //   return const DesktopLandingPage();
    // }

    // return const MobileLandingPage();
  }
}