import 'package:flutter/material.dart';
import '../Services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});


  @override
  State<RegisterPage> createState() => _RegisterPageState();
}


class _RegisterPageState extends State<RegisterPage> {

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final authService = AuthService();

void register() async {

    try {

      final response = await authService.signUp(
        emailController.text.trim(),
        passwordController.text.trim(),
      );


      final user = response.user;


      if (user != null) {

        await authService.createProfile(
          userId: user.id,
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          phoneNumber: phoneController.text.trim(),
        );

      }


      print("Registration successful");


    } catch(e) {

      print(e);
    }
  }
  // void register() async {

  //   try {

  //     await authService.signUp(
  //       emailController.text.trim(),
  //       passwordController.text.trim(),
  //     );


  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Account created!"),
  //       ),
  //     );


  //   } catch(e){

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(e.toString()),
  //       ),
  //     );

  //   }

  // }


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
              controller: firstNameController,
              decoration: const InputDecoration(
              labelText: "First Name",
            ),
          ),

            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
              labelText: "Last Name",
            ),
          ),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
              labelText: "Phone Number",
            ),
          ),

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