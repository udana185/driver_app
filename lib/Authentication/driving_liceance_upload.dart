// TODO: Temporary workaround for development:
// If Firebase Storage upload fails, the app still updates Realtime Database
// with "upload_failed" placeholder values so the verification flow can continue.
// Replace this later with proper URL handling once Storage access/rules are fixed.

import 'dart:io';
import 'package:driver_app/Global/global.dart';
import 'package:driver_app/tabPages/home_tab.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:driver_app/MainScreens/main_screen.dart';

class DrivingLiceanceUpload extends StatefulWidget {
  const DrivingLiceanceUpload({super.key});

  @override
  State<DrivingLiceanceUpload> createState() => _DrivingLiceanceUploadState();
}

class _DrivingLiceanceUploadState extends State<DrivingLiceanceUpload> {
  final ImagePicker _picker = ImagePicker();

  File? frontImage;
  File? backImage;
  bool isUploading = false;

  Future<void> pickFrontImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        frontImage = File(image.path);
      });
    }
  }

  Future<void> pickBackImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        backImage = File(image.path);
      });
    }
  }

  Future<void> uploadLicenseToFirebase() async {
    if (frontImage == null || backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture both images")),
      );
      return;
    }

    try {
      setState(() {
        isUploading = true;
      });

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      String uid = user.uid;

      String frontUrl = "";
      String backUrl = "";

      try {
        final frontRef = FirebaseStorage.instance
            .ref()
            .child("drivers/$uid/license_front.jpg");

        final backRef = FirebaseStorage.instance
            .ref()
            .child("drivers/$uid/license_back.jpg");

        await frontRef.putFile(frontImage!);
        await backRef.putFile(backImage!);

        frontUrl = await frontRef.getDownloadURL();
        backUrl = await backRef.getDownloadURL();
      } catch (storageError) {
        debugPrint("Storage upload failed: $storageError");

        // Temporary fallback so verification flow can continue
        frontUrl = "upload_failed";
        backUrl = "upload_failed";
      }

      await FirebaseDatabase.instance.ref().child("drivers").child(uid).update({
        "licenceFrontUrl": frontUrl,
        "licenceBackUrl": backUrl,
        "status": "pending_verification",
        "verificationSubmitted": true,
        "verificationApproved": false,
      });

      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verification details submitted."),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => MainScreen()),
            (route) => false,
      );
    } catch (e) {
      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Upload Driving License",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: isUploading ? null : pickFrontImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: frontImage == null
                    ? const Center(child: Text("Tap to take FRONT photo"))
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(frontImage!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: isUploading ? null : pickBackImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: backImage == null
                    ? const Center(child: Text("Tap to take BACK photo"))
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(backImage!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () {
                  uploadLicenseToFirebase();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                ),
                child: isUploading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : const Text("Upload License"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}