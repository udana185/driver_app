import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/driver_ride_service.dart';

class DriverAvailableRidesPage extends StatefulWidget {
  const DriverAvailableRidesPage({super.key});

  @override
  State<DriverAvailableRidesPage> createState() =>
      _DriverAvailableRidesPageState();
}

class _DriverAvailableRidesPageState extends State<DriverAvailableRidesPage> {

  String? acceptingRideId;

  Future<void> acceptRide(String rideId) async {
    setState(() {
      acceptingRideId = rideId;
    });

    final accepted = await DriverRideService().acceptRide(
      rideId: rideId,
      driverId: "driver1",
      driverName: "Kasun Driver",
      driverPhone: "0770000000",
      driverLat: 6.8213,
      driverLng: 79.9022,
    );

    setState(() {
      acceptingRideId = null;
    });

    if (accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ride Accepted")),
      );

      // Navigate to ongoing ride page later
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ride already accepted")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Rides"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ride_requests')
            .where('status', isEqualTo: 'searching')
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rides = snapshot.data!.docs;

          if (rides.isEmpty) {
            return const Center(child: Text("No rides available"));
          }

          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {

              final ride = rides[index];
              final data = ride.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text("Pickup: ${data['pickupText']}"),
                      const SizedBox(height: 6),
                      Text("Destination: ${data['destinationText']}"),
                      const SizedBox(height: 6),
                      Text("Distance: ${data['distanceText']}"),
                      const SizedBox(height: 6),
                      Text("Duration: ${data['durationText']}"),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: acceptingRideId == ride.id
                              ? null
                              : () => acceptRide(ride.id),
                          child: acceptingRideId == ride.id
                              ? const CircularProgressIndicator()
                              : const Text("Accept Ride"),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}