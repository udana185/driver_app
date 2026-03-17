import 'package:cloud_firestore/cloud_firestore.dart';

class DriverRideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> acceptRide({
    required String rideId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required double driverLat,
    required double driverLng,
  }) async {
    final docRef = _firestore.collection('ride_requests').doc(rideId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception("Ride not found");
      }

      final data = snapshot.data() as Map<String, dynamic>;

      if (data['status'] != 'searching') {
        return false;
      }

      transaction.update(docRef, {
        'status': 'accepted',
        'acceptedBy': driverId,
        'acceptedAt': FieldValue.serverTimestamp(),
        'driver': {
          'name': driverName,
          'phone': driverPhone,
          'location': {
            'lat': driverLat,
            'lng': driverLng,
          }
        }
      });

      return true;
    });
  }
}