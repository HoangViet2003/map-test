import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapService {
  final String _googleApiKey =
      'AIzaSyDWnQJ-1kPQH8tkUwZLUfvVe22nay9zXjY'; // Replace with your API key

  Future<Position> getCurrentLocation() async {
    // Return fake location in Hanoi
    return Position(
      latitude: 21.0285,
      longitude: 105.8542,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  Future<List<Location>> getCoordinatesFromAddress(String address) async {
    // Return fake locations for testing
    if (address.toLowerCase().contains('hanoi')) {
      return [
        Location(
          latitude: 21.0285,
          longitude: 105.8542,
          timestamp: DateTime.now(),
        )
      ];
    }
    // Default to Times City
    return [
      Location(
        latitude: 20.9865,
        longitude: 105.8695,
        timestamp: DateTime.now(),
      )
    ];
  }

  Future<String> getAddressFromCoordinates(LatLng position) async {
    // Return fake addresses for testing
    if (position.latitude == 21.0285 && position.longitude == 105.8542) {
      return 'Hoan Kiem Lake, Hanoi';
    }
    return 'Times City, Hanoi';
  }

  Future<List<LatLng>> getPolylinePoints(
      LatLng origin, LatLng destination) async {
    List<LatLng> polylineCoordinates = [];

    try {
      final url =
          Uri.parse('https://maps.googleapis.com/maps/api/directions/json?'
              'origin=${origin.latitude},${origin.longitude}'
              '&destination=${destination.latitude},${destination.longitude}'
              '&mode=driving'
              '&key=$_googleApiKey');

      final response = await http.get(url);
      print("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          // Get the encoded polyline from overview_polyline
          final points = PolylinePoints()
              .decodePolyline(data['routes'][0]['overview_polyline']['points']);

          // Convert to LatLng coordinates
          polylineCoordinates = points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          print("Successfully decoded ${polylineCoordinates.length} points");
        } else {
          print(
              "Directions API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}");
        }
      }
    } catch (e) {
      print("Error getting route: $e");
    }

    return polylineCoordinates;
  }
}
