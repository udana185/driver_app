import 'package:driver_app/Authentication/signup_screen_two.dart';
import 'package:driver_app/splash_screen/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../Global/global.dart';
import '../widgets/progress_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  void validateForm() {
    if (emailTextEditingController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Email is required.");
    } else if (!emailTextEditingController.text.trim().contains("@")) {
      Fluttertoast.showToast(msg: "Email is not valid.");
    } else if (passwordTextEditingController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Password is required.");
    } else {
      loginDriverNow();
    }
  }

  Future<void> loginDriverNow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return ProgressDialog(message: "Processing, Please wait...");
      },
    );

    try {
      final UserCredential userCredential =
      await fAuth.signInWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      );

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        if (mounted) {
          Navigator.pop(context);
        }
        Fluttertoast.showToast(msg: "Error occurred during login.");
        return;
      }

      DatabaseReference driverRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(firebaseUser.uid);

      DatabaseEvent driverEvent = await driverRef.once();

      if (driverEvent.snapshot.value == null) {
        await fAuth.signOut();

        if (mounted) {
          Navigator.pop(context);
        }

        Fluttertoast.showToast(
          msg: "No driver record found for this account.",
        );
        return;
      }

      currentFirebaseUser = firebaseUser;

      if (mounted) {
        Navigator.pop(context);
      }

      Fluttertoast.showToast(msg: "Login successful.");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const MySplashScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      Fluttertoast.showToast(msg: "Error: ${e.message}");
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    emailTextEditingController.dispose();
    passwordTextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset("images/chill_ride_light.png"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: emailTextEditingController,
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: passwordTextEditingController,
                keyboardType: TextInputType.text,
                obscureText: true,
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  validateForm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                ),
                child: const Text(
                  "Sign In",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton(
                child: const Text(
                  "Do no have an account? Signup Here",
                  style: TextStyle(color: Colors.grey),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const SignupScreenTwo(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}