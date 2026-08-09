import 'package:flutter/material.dart';
import 'package:family_saas/Pages/Website/landing_page.dart';
import 'package:family_saas/Pages/App/landing_page.dart';


class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= 900) {
      return const DesktopLandingPage();
    }

    return const MobileLandingPage();
  }
}


// class LandingPage extends StatefulWidget {
//   const LandingPage({super.key});


//   @override
//   State<LandingPage> createState() => _LandingPageState();
// }


// class _LandingPageState extends State<LandingPage> {


//   @override
//   Widget build(BuildContext context){

//     return Scaffold(
//     //TODO: Update UI for this page.
//       appBar: AppBar(
//         title: const Text("Welcome to Folktri"),
//       ),


//       body: Padding(

//         padding: const EdgeInsets.all(20),

//         child: Column(

//           children: [
//             Text("A secure home for your family's memories. Launching Soon. Join our waitlist."),
//           ],
//         ),
//       ),
//     );
//   }
// }