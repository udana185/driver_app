import 'package:driver_app/Global/global.dart';
import 'package:driver_app/splash_screen/splash_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ProfileTabPage extends StatefulWidget {
  const ProfileTabPage({super.key});

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends State<ProfileTabPage> {
  bool isLoading = true;

  String driverName = "";
  String driverPhone = "";
  String driverStatus = "";
  String profileImageUrl = "";
  String licenceFrontUrl = "";
  String licenceBackUrl = "";
  String medicalCertificateUrl = "";

  @override
  void initState() {
    super.initState();
    fetchDriverProfileData();
  }

  Future<void> fetchDriverProfileData() async {
    try {
      if (currentFirebaseUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      DatabaseReference driverRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(currentFirebaseUser!.uid);

      DatabaseEvent event = await driverRef.once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> driverData =
        event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          driverName = (driverData["name"] ?? "").toString();
          driverPhone = (driverData["phone"] ?? "").toString();
          driverStatus = (driverData["status"] ?? "registered").toString();
          profileImageUrl = (driverData["profileImageUrl"] ?? "").toString();
          licenceFrontUrl = (driverData["licenceFrontUrl"] ?? "").toString();
          licenceBackUrl = (driverData["licenceBackUrl"] ?? "").toString();
          medicalCertificateUrl =
              (driverData["medicalCertificateUrl"] ?? "").toString();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String getReadableStatus(String status) {
    switch (status) {
      case "registered":
        return "Verification Required";
      case "pending_verification":
        return "Pending Verification";
      case "verified":
        return "Verified";
      case "rejected":
        return "Rejected";
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "verified":
        return Colors.green;
      case "pending_verification":
        return Colors.orange;
      case "rejected":
        return Colors.red;
      case "registered":
      default:
        return Colors.blueGrey;
    }
  }

  bool isValidImageUrl(String url) {
    return url.isNotEmpty && url != "upload_failed";
  }

  Widget buildDocumentCard({
    required String title,
    required String imageUrl,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isValidImageUrl(imageUrl)
                  ? Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Text(
                      "Unable to load image",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                },
              )
                  : Container(
                height: 180,
                width: double.infinity,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Text(
                  "Image unavailable",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfileImage() {
    return CircleAvatar(
      radius: 45,
      backgroundColor: Colors.grey.shade300,
      backgroundImage:
      isValidImageUrl(profileImageUrl) ? NetworkImage(profileImageUrl) : null,
      child: !isValidImageUrl(profileImageUrl)
          ? const Icon(
        Icons.person,
        size: 50,
        color: Colors.white,
      )
          : null,
    );
  }

  Future<void> logoutDriver() async {
    await fAuth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (c) => const MySplashScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Account",
          style: TextStyle(fontSize: 25),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: fetchDriverProfileData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    buildProfileImage(),
                    const SizedBox(height: 14),
                    Text(
                      driverName.isEmpty ? "No Name" : driverName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      driverPhone.isEmpty ? "No Phone Number" : driverPhone,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(driverStatus).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        getReadableStatus(driverStatus),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: getStatusColor(driverStatus),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            buildDocumentCard(
              title: "Driving License - Front",
              imageUrl: licenceFrontUrl,
            ),
            buildDocumentCard(
              title: "Driving License - Back",
              imageUrl: licenceBackUrl,
            ),
            buildDocumentCard(
              title: "Medical Certificate",
              imageUrl: medicalCertificateUrl,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: logoutDriver,
                icon: const Icon(Icons.logout),
                label: const Text("Log out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}