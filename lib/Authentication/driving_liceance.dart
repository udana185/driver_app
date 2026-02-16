import 'package:driver_app/Authentication/driving_liceance_upload.dart';
import 'package:flutter/material.dart';

class DrivingLiceance extends StatefulWidget {
  const DrivingLiceance({super.key});

  @override
  State<DrivingLiceance> createState() => _DrivingLiceanceState();
}

class _DrivingLiceanceState extends State<DrivingLiceance> {
  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFF1A1A1A),
          title: Image.asset("images/chill_ride.png",
            height: 60,
            fit: BoxFit.contain,
          ),
          centerTitle: true,

        ),
      body: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              SizedBox(height: 30),

              Text("Hello, Udana!",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text("Your account has been created.",
                style: TextStyle(
                  fontSize: 13,
                  //fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c)=> DrivingLiceanceUpload()));
                            // Upload functionality goes here
                            // You can integrate image_picker package later
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  ),
                  child: Text("Upload Driving Liceance"),
                ),
              ),
            ],
        ),
      ),
    );
  }
}
