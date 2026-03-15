import 'package:driver_app/Authentication/driving_liceance.dart';
import 'package:driver_app/Authentication/login_screen.dart';
import 'package:driver_app/Global/global.dart';
import 'package:driver_app/MainScreens/main_screen.dart';
import 'package:driver_app/tabPages/home_tab.dart';
import 'package:driver_app/widgets/progress_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignupScreenTwo extends StatefulWidget {
  const SignupScreenTwo({super.key});

  @override
  State<SignupScreenTwo> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreenTwo> {
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  validateForm() {
    if (nameTextEditingController.text.trim().length < 3) {
      Fluttertoast.showToast(msg: "Name must be at least 3 characters.");
    } else if (emailTextEditingController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Email is required.");
    } else if (!emailTextEditingController.text.trim().contains("@")) {
      Fluttertoast.showToast(msg: "Email is not valid.");
    } else if (phoneTextEditingController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Phone number is required.");
    } else if (!RegExp(r'^0[0-9]+$')
        .hasMatch(phoneTextEditingController.text.trim())) {
      Fluttertoast.showToast(
          msg: "Phone number must start with 0 and contain only numbers.");
    } else if (phoneTextEditingController.text.trim().length != 10) {
      Fluttertoast.showToast(msg: "Phone number must be exactly 10 digits.");
    } else if (passwordTextEditingController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Password is required.");
    } else if (passwordTextEditingController.text.trim().length < 6) {
      Fluttertoast.showToast(msg: "Password must be at least 6 characters.");
    } else {
      saveDriverInfoNow();
    }
  }

  saveDriverInfoNow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return ProgressDialog(message: "Processing, Please wait...");
      },
    );

    try {
      final UserCredential userCredential =
      await fAuth.createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      );

      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        Map<String, dynamic> driverMap = {
          "id": firebaseUser.uid,
          "name": nameTextEditingController.text.trim(),
          "email": emailTextEditingController.text.trim(),
          "phone": phoneTextEditingController.text.trim(),
          "status": "registered",
          "isEligible": false,
          "isOnline": false,
          "licenceUrl": "",
          "medicalCertificateUrl": "",
          "verificationSubmitted": false,
          "verificationApproved": false,
        };

        DatabaseReference driversRef =
        FirebaseDatabase.instance.ref().child("drivers");

        await driversRef.child(firebaseUser.uid).set(driverMap);

        currentFirebaseUser = firebaseUser;

        if (mounted) {
          Navigator.pop(context); // closes progress dialog
        }

        Fluttertoast.showToast(msg: "Account has been created.");

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => MainScreen()),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
        }
        Fluttertoast.showToast(msg: "Account has not been created.");
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
    nameTextEditingController.dispose();
    emailTextEditingController.dispose();
    phoneTextEditingController.dispose();
    passwordTextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset("images/chill_ride_light.png"),
              ),
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white,
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Driver Registration",
                          style: TextStyle(
                            fontSize: 24,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: nameTextEditingController,
                        style: const TextStyle(color: Colors.grey),
                        decoration: const InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailTextEditingController,
                        keyboardType: TextInputType.emailAddress,
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
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneTextEditingController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.grey),
                        decoration: const InputDecoration(
                          labelText: "Phone",
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () {
                          validateForm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A),
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      TextButton(
                        child: const Text(
                          "Already have an account? Login Here",
                          style: TextStyle(color: Colors.grey),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const LoginScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}