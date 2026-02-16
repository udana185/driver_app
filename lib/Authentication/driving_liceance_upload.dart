import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DrivingLiceanceUpload extends StatefulWidget {
  const DrivingLiceanceUpload({super.key});

  @override
  State<DrivingLiceanceUpload> createState() => _DrivingLiceanceUploadState();
}

class _DrivingLiceanceUploadState extends State<DrivingLiceanceUpload> {

  final ImagePicker _picker = ImagePicker();

  File? frontImage;
  File? backImage;





  Future<void> uploadLicenseToFirebase() async {
    if (frontImage == null || backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please capture both images")),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      String uid = user.uid;

      // Storage references
      final frontRef = FirebaseStorage.instance
          .ref()
          .child("drivers/$uid/license_front.jpg");

      final backRef = FirebaseStorage.instance
          .ref()
          .child("drivers/$uid/license_back.jpg");

      // Upload images
      await frontRef.putFile(frontImage!);
      await backRef.putFile(backImage!);

      // Get download URLs
      String frontUrl = await frontRef.getDownloadURL();
      String backUrl = await backRef.getDownloadURL();

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection("drivers")
          .doc(uid)
          .set({
        "licenseFront": frontUrl,
        "licenseBack": backUrl,
        "status": "pending",
        "uploadedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Your driving license has been uploaded successfully!")),
      );



    }
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }






  Future<void> pickFrontImage() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        frontImage = File(image.path);
      });
    }
  }

  Future<void> pickBackImage() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        backImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Upload Driving License",
        style: TextStyle(
          color: Colors.white,
        ),),
        centerTitle: true,
          leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
          ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // Front image box
            GestureDetector(
              onTap: pickFrontImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: frontImage == null
                    ? Center(child: Text("Tap to take FRONT photo"))
                    : Image.file(frontImage!, fit: BoxFit.cover),
              ),
            ),

            SizedBox(height: 20),

            // Back image box
            GestureDetector(
              onTap: pickBackImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: backImage == null
                    ? Center(child: Text("Tap to take BACK photo"))
                    : Image.file(backImage!, fit: BoxFit.cover),
              ),
            ),

            SizedBox(height: 30),

            ElevatedButton(

              onPressed: () {
                if (frontImage == null || backImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please capture both images")),
                  );
                } else {
                  uploadLicenseToFirebase;
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              ),
              child: Text("Upload License"),
            ),
          ],
        ),
      ),
    );
  }
}

