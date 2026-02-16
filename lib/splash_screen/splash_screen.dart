import 'dart:async';

import 'package:driver_app/Authentication/login_screen.dart';
import 'package:driver_app/Authentication/signup_screen.dart';
import 'package:driver_app/Authentication/signup_screen_two.dart';
import 'package:driver_app/Global/global.dart';
import 'package:driver_app/MainScreens/main_screen.dart';
import 'package:flutter/material.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({super.key});

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen>
{
  startTimer()
  {
    Timer(const Duration(seconds: 1), () async {
      if (await fAuth.currentUser != null)
      {
        currentFirebaseUser = fAuth.currentUser;
        Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()),);
      }
      else {
        Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()),);
      }
    });
  }

@override
  void initState() {

    super.initState();

    startTimer();
  }


  @override
  Widget build(BuildContext context)
  {
    return Container(
      color: Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("images/chill_ride.png",width: 200,height: 200,),
             const SizedBox(height: 2,),
            /*const Text(
              "Chill_Ride",
              style: TextStyle(
                fontSize: 60,
                color: Colors.white,
                fontWeight: FontWeight.bold
              ),

            ),*/

          ],
        ),
      ),
    );
  }
}
