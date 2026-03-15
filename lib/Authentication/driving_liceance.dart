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
        backgroundColor: Colors.black,

        // FIX: makes the back arrow white and visible
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text(
          "License Verification",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 20),

            const Icon(
              Icons.verified_user,
              size: 120,
              color: Colors.black,
            ),

            const SizedBox(height: 30),

            const Text(
              "Driver Verification Required",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            const Text(
              "To start accepting rides, please upload your driving license for verification.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ()
                {
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
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Continue to Verification",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}