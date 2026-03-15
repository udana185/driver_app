// TODO: Temporary workaround for development:
// If Firebase Storage upload fails, the app still updates Realtime Database
// with "upload_failed" placeholder values so the verification flow can continue.
// Replace this later with proper URL handling once Storage access/rules are fixed.

import 'dart:io';

import 'package:driver_app/MainScreens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

      final String uid = user.uid;

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

  Widget buildImagePickerCard({
    required String title,
    required String subtitle,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 170,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(16),
        ),
        child: imageFile == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 34,
              color: Colors.black54,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        )
            : Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                imageFile,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Upload Driving License",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Driver Verification",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please upload clear photos of the front and back of your driving license.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              buildImagePickerCard(
                title: "Front Side",
                subtitle: "Tap to capture the front of your license",
                imageFile: frontImage,
                onTap: pickFrontImage,
              ),
              const SizedBox(height: 18),
              buildImagePickerCard(
                title: "Back Side",
                subtitle: "Tap to capture the back of your license",
                imageFile: backImage,
                onTap: pickBackImage,
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
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isUploading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Upload License",
                    style: TextStyle(fontSize: 15),
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