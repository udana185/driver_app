import 'dart:async';

import 'package:driver_app/Authentication/driving_liceance.dart';
import 'package:driver_app/Global/global.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  GoogleMapController? newGoogleMapController;
  final Completer<GoogleMapController> _controllerGoogleMap =
  Completer<GoogleMapController>();

  String driverStatus = "loading";

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
    fetchDriverStatus();
  }

  Future<void> fetchDriverStatus() async {
    try {
      if (currentFirebaseUser == null) {
        setState(() {
          driverStatus = "registered";
        });
        return;
      }

      DatabaseReference driverRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(currentFirebaseUser!.uid);

      DatabaseEvent driverEvent = await driverRef.once();

      if (driverEvent.snapshot.value != null) {
        Map<dynamic, dynamic> driverData =
        driverEvent.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          driverStatus = (driverData["status"] ?? "registered").toString();
        });
      } else {
        setState(() {
          driverStatus = "registered";
        });
      }
    } catch (e) {
      setState(() {
        driverStatus = "registered";
      });
    }
  }

  Future<void> checkIfLocationPermissionAllowed() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("Location permission permanently denied");
      return;
    }
  }

  Future<void> locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition = CameraPosition(
      target: latLngPosition,
      zoom: 14,
    );

    newGoogleMapController?.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  }

  Widget buildVerificationCard() {
    if (driverStatus == "verified" || driverStatus == "loading") {
      return const SizedBox.shrink();
    }

    String title = "";
    String message = "";
    bool showButton = false;

    if (driverStatus == "registered") {
      title = "Verification Required";
      message =
      "Complete your verification to become eligible as a driver and receive ride requests.";
      showButton = true;
    } else if (driverStatus == "pending_verification") {
      title = "Verification Pending";
      message =
      "Your documents are under review. You will become eligible once verification is approved.";
      showButton = false;
    } else if (driverStatus == "rejected") {
      title = "Verification Rejected";
      message =
      "Your submitted documents were rejected. Please continue to verification and upload valid documents again.";
      showButton = true;
    } else {
      title = "Verification Required";
      message =
      "Your account needs verification before you can start driving.";
      showButton = true;
    }

    return Positioned(
      top: 20,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orangeAccent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (showButton) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const DrivingLiceance(),
                          ),
                        ).then((_) {
                          fetchDriverStatus();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                      ),
                      child: const Text(
                        "Continue to Verification",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller) {
            _controllerGoogleMap.complete(controller);
            newGoogleMapController = controller;
            locatePosition();
          },
        ),
        buildVerificationCard(),
      ],
    );
  }
}