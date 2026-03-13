import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage>
{

  GoogleMapController? newGoogleMapController;


  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
  }

  Future<void> checkIfLocationPermissionAllowed() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permission permanently denied");
      return;
    }
  }

  Future<void> locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng latLngPosition =
    LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition = CameraPosition(
      target: latLngPosition,
      zoom: 14,
    );

    newGoogleMapController?.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  }


  final Completer<GoogleMapController> _controllerGoogleMap = Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          myLocationEnabled: true,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller)
          {
            _controllerGoogleMap.complete(controller);
            newGoogleMapController = controller;

            locatePosition();
          },

        ),
      ],
    );
  }
}
