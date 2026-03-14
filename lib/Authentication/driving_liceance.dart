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
        backgroundColor: const Color(0xFF1A1A1A),
        title: Image.asset(
          "images/chill_ride.png",
          height: 60,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),
            const Text(
              "Driver Verification",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Upload clear front and back images of your driving licence to continue verification.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const DrivingLiceanceUpload(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                ),
                child: const Text("Upload Driving License"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}