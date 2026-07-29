import 'package:flutter/material.dart';
import '../Services/auth_service.dart';
import '../Pages/create_account.dart';


class SignInPage extends StatefulWidget {
  const SignInPage({super.key});


  @override
  State<SignInPage> createState() => _SignInPageState();
}


class _SignInPageState extends State<SignInPage> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final authService = AuthService();


  void register() async {

    try {

      await authService.signIn(
        emailController.text,
        passwordController.text,
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
        title: const Text("Sign In"),
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
              child: const Text("Login"),
            ),

            //The registration button
            TextButton(
              onPressed: () {

              Navigator.push(
                context,
              MaterialPageRoute(
               builder: (context) => const RegisterPage(),
              ),
            );

          },
          child: const Text(
            "Create an account",
          ),
        ),

          ],
        ),
      ),
    );
  }
}
