import 'package:flutter/material.dart';
import '../Services/auth_service.dart';

//TODO: Add Name
//TODO: Add Phone Number

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});


  @override
  State<RegisterPage> createState() => _RegisterPageState();
}


class _RegisterPageState extends State<RegisterPage> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final authService = AuthService();


  void register() async {

    try {

      await authService.signUp(
        emailController.text.trim(),
        passwordController.text.trim(),
      );


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created!"),
        ),
      );


    } catch(e){

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );

    }

  }


  @override
  Widget build(BuildContext context){

    return Scaffold(
    //TODO: Update UI for this page.
      appBar: AppBar(
        title: const Text("Create Family Account"),
      ),


      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),


            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
              ),
            ),


            ElevatedButton(
              onPressed: register,
              child: const Text("Create Account"),
            )

          ],
        ),
      ),
    );
  }
}