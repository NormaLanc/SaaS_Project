import 'package:flutter/material.dart';
//import '../Services/auth_service.dart';


class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});


  @override
  State<FamilyPage> createState() => _FamilyPageState();
}


class _FamilyPageState extends State<FamilyPage> {

  

  @override
  Widget build(BuildContext context){

    return Scaffold(

      appBar: AppBar(
        title: const Text("Family Dashboard"),
      ),


      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Text("Welcome to My Family OS")
      ),
    );
  }
}
