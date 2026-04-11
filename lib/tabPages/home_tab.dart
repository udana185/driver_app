import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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

class _HomeTabPageState extends State<HomeTabPage>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? newGoogleMapController;
  final Completer<GoogleMapController> _controllerGoogleMap =
  Completer<GoogleMapController>();

  String driverStatus = "loading";
  bool isOnline = false;

  DatabaseReference? driverRef;
  StreamSubscription<DatabaseEvent>? driverStatusSubscription;

  Position? currentDriverPosition;

  static const double searchRadiusInMeters = 100000; // 100 km
  static const int maxVisibleRequests = 5;

  List<Map<String, dynamic>> nearbyRideRequests = [];
  Set<Marker> rideMarkers = {};
  bool isViewingRequests = false;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
    listenToDriverStatus();
  }

  void listenToDriverStatus() {
    try {
      if (currentFirebaseUser == null) {
        setState(() {
          driverStatus = "registered";
          isOnline = false;
        });
        return;
      }

      driverRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(currentFirebaseUser!.uid);

      driverStatusSubscription = driverRef!.onValue.listen((event) {
        if (!mounted) return;

        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> driverData =
          event.snapshot.value as Map<dynamic, dynamic>;

          setState(() {
            driverStatus = (driverData["status"] ?? "registered").toString();
            isOnline = driverData["isOnline"] == true;
          });

          if (driverStatus != "verified") {
            clearRideRequestView();
          }
        } else {
          setState(() {
            driverStatus = "registered";
            isOnline = false;
          });
          clearRideRequestView();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        driverStatus = "registered";
        isOnline = false;
      });
      clearRideRequestView();
    }
  }

  Future<void> toggleOnlineStatus() async {
    if (currentFirebaseUser == null) return;

    if (driverStatus != "verified") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must be verified before going online."),
        ),
      );
      return;
    }

    final bool newStatus = !isOnline;
    await setOnlineStatus(newStatus, showSnackBar: true);

    if (newStatus) {
      await fetchNearbyRideRequests(showSummaryDialog: true);
    }
  }

  Future<void> setOnlineStatus(
      bool online, {
        bool showSnackBar = false,
      }) async {
    if (currentFirebaseUser == null) return;

    try {
      await FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(currentFirebaseUser!.uid)
          .update({
        "isOnline": online,
      });

      if (!mounted) return;

      setState(() {
        isOnline = online;
      });

      if (!online) {
        clearRideRequestView();
        await focusOnDriverLocation();
      }

      if (showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              online ? "You are now online." : "You are now offline.",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update online status: $e"),
        ),
      );
    }
  }

  Future<void> fetchNearbyRideRequests({
    bool showSummaryDialog = false,
  }) async {
    if (!isOnline || driverStatus != "verified") return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      currentDriverPosition = position;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("ride_requests")
          .where("status", isEqualTo: "searching")
          .get();

      List<Map<String, dynamic>> filteredRequests = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final acceptedBy = data["acceptedBy"];
        if (acceptedBy != null && acceptedBy.toString().isNotEmpty) {
          continue;
        }

        final pickup = data["pickup"];
        if (pickup == null || pickup["lat"] == null || pickup["lng"] == null) {
          continue;
        }

        final double pickupLat = (pickup["lat"] as num).toDouble();
        final double pickupLng = (pickup["lng"] as num).toDouble();

        final double distanceToPickup = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          pickupLat,
          pickupLng,
        );

        if (distanceToPickup <= searchRadiusInMeters) {
          filteredRequests.add({
            "requestId": doc.id,
            "data": data,
            "distanceToPickupMeters": distanceToPickup,
          });
        }
      }

      filteredRequests.sort((a, b) {
        return (a["distanceToPickupMeters"] as double)
            .compareTo(b["distanceToPickupMeters"] as double);
      });

      if (filteredRequests.length > maxVisibleRequests) {
        filteredRequests = filteredRequests.take(maxVisibleRequests).toList();
      }

      setState(() {
        nearbyRideRequests = filteredRequests;
      });

      if (showSummaryDialog) {
        showNearbySummaryDialog(filteredRequests.length);
      } else {
        if (isViewingRequests) {
          showRequestsOnMap();
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              filteredRequests.isEmpty
                  ? "No nearby ride requests found."
                  : "Showing ${filteredRequests.length} nearby ride request(s).",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to fetch nearby ride requests: $e"),
        ),
      );
    }
  }

  void showNearbySummaryDialog(int count) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        if (count > 0) {
          return AlertDialog(
            title: const Text("Nearby Requests"),
            content: Text(
              "$count ride request(s) found within ${(searchRadiusInMeters / 1000).toStringAsFixed(0)} km.",
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await setOnlineStatus(false, showSnackBar: true);
                },
                child: const Text("Go Offline"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showRequestsOnMap();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                ),
                child: const Text("View Requests"),
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: const Text("No Nearby Requests"),
            content: Text(
              "No ride requests were found within ${(searchRadiusInMeters / 1000).toStringAsFixed(0)} km.",
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await setOnlineStatus(false, showSnackBar: true);
                },
                child: const Text("Go Offline"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Stay Online"),
              ),
            ],
          );
        }
      },
    );
  }

  void showRequestsOnMap() {
    Set<Marker> markers = {};

    if (currentDriverPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("driver_location"),
          position: LatLng(
            currentDriverPosition!.latitude,
            currentDriverPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(
            title: "You",
            snippet: "Current location",
          ),
        ),
      );
    }

    for (var ride in nearbyRideRequests) {
      final String requestId = ride["requestId"] as String;
      final Map<String, dynamic> data = ride["data"] as Map<String, dynamic>;
      final pickup = data["pickup"];

      final double pickupLat = (pickup["lat"] as num).toDouble();
      final double pickupLng = (pickup["lng"] as num).toDouble();
      final double distanceToPickupMeters =
      ride["distanceToPickupMeters"] as double;

      markers.add(
        Marker(
          markerId: MarkerId(requestId),
          position: LatLng(pickupLat, pickupLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: "Ride: ${data["distanceText"] ?? "Unknown"}",
            snippet:
            "Pickup: ${formatDistanceToPickup(distanceToPickupMeters)}",
          ),
          onTap: () {
            showRideRequestPopup(ride);
          },
        ),
      );
    }

    setState(() {
      rideMarkers = markers;
      isViewingRequests = true;
    });

    fitMapToMarkers();
  }

  void showRideRequestPopup(Map<String, dynamic> ride) {
    if (!mounted) return;

    final data = ride["data"] as Map<String, dynamic>;
    final String requestId = ride["requestId"] as String;
    final double distanceToPickupMeters =
    ride["distanceToPickupMeters"] as double;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ride Request"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pickup: ${data["pickupText"] ?? "Unknown"}"),
              const SizedBox(height: 8),
              Text("Destination: ${data["destinationText"] ?? "Unknown"}"),
              const SizedBox(height: 8),
              Text("Ride Distance: ${data["distanceText"] ?? "Unknown"}"),
              const SizedBox(height: 8),
              Text("Ride Time: ${data["durationText"] ?? "Unknown"}"),
              const SizedBox(height: 8),
              Text(
                "Distance to Pickup: ${formatDistanceToPickup(distanceToPickupMeters)}",
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Reject"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await acceptRide(requestId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
              ),
              child: const Text("Accept"),
            ),
          ],
        );
      },
    );
  }

  void fitMapToMarkers() {
    if (rideMarkers.isEmpty || newGoogleMapController == null) return;

    double? minLat, maxLat, minLng, maxLng;

    for (final marker in rideMarkers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = (minLat == null || lat < minLat) ? lat : minLat;
      maxLat = (maxLat == null || lat > maxLat) ? lat : maxLat;
      minLng = (minLng == null || lng < minLng) ? lng : minLng;
      maxLng = (maxLng == null || lng > maxLng) ? lng : maxLng;
    }

    if (minLat == null ||
        maxLat == null ||
        minLng == null ||
        maxLng == null) {
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    newGoogleMapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  Future<void> focusOnDriverLocation() async {
    try {
      if (currentDriverPosition == null) {
        final freshPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );
        currentDriverPosition = freshPosition;
      }

      if (currentDriverPosition == null || newGoogleMapController == null) return;

      final latLng = LatLng(
        currentDriverPosition!.latitude,
        currentDriverPosition!.longitude,
      );

      final cameraPosition = CameraPosition(
        target: latLng,
        zoom: 16,
      );

      newGoogleMapController!.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    } catch (e) {
      debugPrint("Failed to focus on driver location: $e");
    }
  }

  void clearRideRequestView() {
    setState(() {
      nearbyRideRequests = [];
      rideMarkers = {};
      isViewingRequests = false;
    });
  }

  String formatDistanceToPickup(double meters) {
    if (meters >= 1000) {
      return "${(meters / 1000).toStringAsFixed(1)} km away";
    }
    return "${meters.toStringAsFixed(0)} m away";
  }

  Future<void> acceptRide(String requestId) async {
    if (currentFirebaseUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("ride_requests")
          .doc(requestId)
          .update({
        "status": "accepted",
        "acceptedBy": currentFirebaseUser!.uid,
      });

      setState(() {
        nearbyRideRequests.removeWhere((ride) => ride["requestId"] == requestId);
        rideMarkers.removeWhere((marker) => marker.markerId.value == requestId);
      });

      fitMapToMarkers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ride request accepted."),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to accept ride: $e"),
        ),
      );
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
    try {
      Position? lastKnownPosition = await Geolocator.getLastKnownPosition();

      if (lastKnownPosition != null) {
        currentDriverPosition = lastKnownPosition;

        LatLng latLngPosition = LatLng(
          lastKnownPosition.latitude,
          lastKnownPosition.longitude,
        );

        CameraPosition cameraPosition = CameraPosition(
          target: latLngPosition,
          zoom: 14,
        );

        newGoogleMapController?.animateCamera(
          CameraUpdate.newCameraPosition(cameraPosition),
        );
      }

      Position freshPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      currentDriverPosition = freshPosition;

      LatLng freshLatLng = LatLng(
        freshPosition.latitude,
        freshPosition.longitude,
      );

      CameraPosition freshCameraPosition = CameraPosition(
        target: freshLatLng,
        zoom: 16,
      );

      newGoogleMapController?.animateCamera(
        CameraUpdate.newCameraPosition(freshCameraPosition),
      );

      debugPrint(
        "Driver current location: ${freshPosition.latitude}, ${freshPosition.longitude}",
      );
      debugPrint("Location accuracy: ${freshPosition.accuracy} meters");
    } catch (e) {
      debugPrint("Failed to get driver location: $e");
    }
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
                        );
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

  Widget buildRideInfoCard() {
    return const SizedBox.shrink();
  }

  Widget buildOnlineOfflineToggle() {
    if (driverStatus != "verified") {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOnline ? "Online" : "Offline",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isOnline ? Colors.green : Colors.red,
                ),
              ),
              Switch(
                value: isOnline,
                onChanged: (value) {
                  toggleOnlineStatus();
                },
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
                inactiveTrackColor: Colors.red.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRefreshRequestsButton() {
    if (driverStatus != "verified" || !isOnline) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 100,
      right: 16,
      child: SafeArea(
        child: FloatingActionButton.extended(
          onPressed: () {
            fetchNearbyRideRequests(showSummaryDialog: false);
          },
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.refresh),
          label: const Text("Refresh"),
        ),
      ),
    );
  }

  @override
  void dispose() {
    driverStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: rideMarkers,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller) {
            _controllerGoogleMap.complete(controller);
            newGoogleMapController = controller;
            locatePosition();
          },
        ),
        buildVerificationCard(),
        buildRideInfoCard(),
        buildRefreshRequestsButton(),
        buildOnlineOfflineToggle(),
      ],
    );
  }
}