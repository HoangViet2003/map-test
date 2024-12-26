import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map_provider.dart';

class MapService {
  final String _apiKey =
      'AIzaSyDWnQJ-1kPQH8tkUwZLUfvVe22nay9zXjY'; // Replace with your API key

  Future<Position> getCurrentLocation() async {
    // Return fake location in Hanoi
    return Position(
      latitude: 21.024387195557942,
      longitude: 105.79029869154314,
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

  Future<List<PlaceAutocomplete>> getPlaceSuggestions(String input) async {
    if (input.isEmpty) return [];

    const hanoiLat = 21.0285;
    const hanoiLng = 105.8542;
    const radius = 10000; // Radius in meters (50 km)

    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=$input'
            '&components=country:vn'
            '&language=vi'
            '&types=geocode|establishment'
            '&location=$hanoiLat,$hanoiLng'
            '&radius=$radius'
            '&key=$_apiKey');

    try {
      print(url);
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions.map((p) => PlaceAutocomplete.fromJson(p)).toList();
        } else {
          print(
              'Place Autocomplete Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Error getting place suggestions: $e');
      return [];
    }
  }

  Future<LatLng?> getPlaceDetails(String placeId) async {
    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/place/details/json'
            '?place_id=$placeId'
            '&fields=geometry'
            '&key=$_apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        } else {
          print(
              'Place Details Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  Future<String> getAddressFromCoordinates(LatLng position) async {
    final url = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${position.latitude},${position.longitude}'
        '&language=vi'
        '&key=$_apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
      return '${position.latitude}, ${position.longitude}';
    } catch (e) {
      return '${position.latitude}, ${position.longitude}';
    }
  }

  Future<List<Polyline>> getPolylinePoints(
      LatLng origin, LatLng destination) async {
    List<Polyline> polylines = [];

    try {
      // Simulate a Google Directions API response
      final Map<String, dynamic> mockDirectionsResponse = {
        'status': 'OK',
        'routes': [
          {
            'legs': [
              {
                'steps': [
                  {
                    'travel_mode': 'WALKING',
                    'polyline': {
                      'points': 'gej_CssaeSK{FdASrA[',
                    },
                  },
                  {
                    'travel_mode': 'TRANSIT',
                    'polyline': {
                      'points':
                          's`j_Cq|aeSCMJCfA[\\INAN?N@J?D@N@`@Fp@NlAXf@LhATdATfB^bBb@nCn@b@mCd@yB^mB`@mBJe@DW\\I|A]ZKHAHC|Bi@^IPEDAhA[TG|HcBd@Gl@Ep@Rp@Vn@XrBr@`@Kj@K~Aa@pBe@REdAUbASdAU~@ObBSLCh@GZCJR\\h@pArBTZvAaAFEXSPKTQl@g@XUAC`CeBlBwAxAgAlA{@RIPCX@dAX\\F`@B~COnE[@?xG]xIc@fHW?A~DQrBQZCRAdAE|@ExBMLAzBINA\\CnAGb@C`DQXAl@Ar@I[yANChBKB?LIf@AdBIp@Eh@Ed@A`@C`@CTAfAEJAn@C|@GfCUTCHAd@i@JKBCNQLMDE\\]FGXWb@a@HItAqAVUJKHGHI@At@s@^]BCZYj@g@JKr@o@\\_@HGBCz@y@RSXW\\]d@c@LKRUBGFIT_@Ra@P[JQlA{BXm@b@{@HMJOt@sAJF',
                    },
                  },
                  {
                    'travel_mode': 'WALKING',
                    'polyline': {
                      'points':
                          '{za_CirdeS?@@@RRtBlBEJIXE`@q@@k@?C@A?A?A@A@ABA@?@AB@BQBYgACIKWUs@K_@K_@MYCGZY',
                    },
                  },
                ],
              },
            ],
          },
        ],
      };

      if (mockDirectionsResponse['status'] == 'OK') {
        final routes = mockDirectionsResponse['routes'] as List;

        for (final route in routes) {
          final legs = (route as Map<String, dynamic>)['legs'] as List;

          for (final leg in legs) {
            final steps = (leg as Map<String, dynamic>)['steps'] as List;

            for (int i = 0; i < steps.length; i++) {
              final step = steps[i] as Map<String, dynamic>;
              final travelMode = step['travel_mode'] as String;
              final points = step['polyline']['points'] as String;

              // Decode the polyline points for this step
              final decodedPoints = PolylinePoints()
                  .decodePolyline(points)
                  .map((point) => LatLng(point.latitude, point.longitude))
                  .toList();

              // Set polyline properties based on travel mode
              Color color;
              int width;
              List<PatternItem> patterns = [];

              switch (travelMode) {
                case 'WALKING':
                  color = Colors.green;
                  width = 4;
                  patterns = [PatternItem.dash(20), PatternItem.gap(10)];
                  break;
                case 'TRANSIT':
                  color = Colors.blue;
                  width = 5;
                  break;
                default:
                  color = Colors.grey;
                  width = 4;
              }

              final polyline = Polyline(
                polylineId: PolylineId('route_${i}_$travelMode'),
                points: decodedPoints,
                color: color,
                width: width,
                patterns: patterns,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              );

              polylines.add(polyline);
            }
          }
        }
      }
    } catch (e) {
      print('Error creating route: $e');
      rethrow;
    }

    return polylines;
  }

  Future<List<Map<String, dynamic>>> getPossibleRoutes(
      LatLng origin, LatLng destination) async {
    final url = Uri.parse('https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&alternatives=true'
        '&mode=transit'
        '&transit_mode=bus'
        '&language=vi'
        '&key=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          return routes.map((route) {
            final leg = route['legs'][0];
            final steps = leg['steps'] as List;

            // Process each step to include transit details
            final processedSteps = steps.map((step) {
              final Map<String, dynamic> processedStep = {
                'travel_mode': step['travel_mode'],
                'duration': step['duration'],
                'distance': step['distance'],
                'html_instructions': step['html_instructions'],
                'polyline': step['polyline'],
              };

              // Add transit details if this is a transit step
              if (step['travel_mode'] == 'TRANSIT' &&
                  step['transit_details'] != null) {
                final transitDetails = step['transit_details'];
                processedStep['transit_details'] = {
                  'departure_stop': {
                    'name': transitDetails['departure_stop']['name'],
                    'location': transitDetails['departure_stop']['location'],
                  },
                  'arrival_stop': {
                    'name': transitDetails['arrival_stop']['name'],
                    'location': transitDetails['arrival_stop']['location'],
                  },
                  'departure_time': transitDetails['departure_time'],
                  'arrival_time': transitDetails['arrival_time'],
                  'headsign': transitDetails['headsign'],
                  'line': {
                    'name': transitDetails['line']['name'],
                    'short_name': transitDetails['line']['short_name'],
                    'vehicle': {
                      'name': transitDetails['line']['vehicle']['name'],
                      'type': transitDetails['line']['vehicle']['type'],
                      'icon': transitDetails['line']['vehicle']['icon'],
                    },
                    'agencies': transitDetails['line']['agencies'],
                  },
                  'num_stops': transitDetails['num_stops'],
                };
              }

              return processedStep;
            }).toList();

            return {
              'distance': leg['distance'],
              'duration': leg['duration'],
              'steps': processedSteps,
              'overview_polyline': route['overview_polyline']['points'],
              'fare': route['fare'],
              'summary': route['summary'],
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting routes: $e');
      return [];
    }
  }

  Future<List<Polyline>> getPolylineFromRoute(
      Map<String, dynamic> route) async {
    List<Polyline> polylines = [];
    try {
      final steps = route['steps'] as List;

      for (int i = 0; i < steps.length; i++) {
        final step = steps[i] as Map<String, dynamic>;
        final travelMode = step['travel_mode'] as String;
        final points = step['polyline']['points'] as String;

        final polylinePoints = PolylinePoints();
        final decodedPoints = polylinePoints.decodePolyline(points);
        final List<LatLng> polylineCoordinates = decodedPoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        // Set polyline properties based on travel mode
        Color color;
        int width;
        List<PatternItem> patterns = [];

        switch (travelMode) {
          case 'WALKING':
            color = Colors.green;
            width = 4;
            patterns = [PatternItem.dash(20), PatternItem.gap(10)];
            break;
          case 'TRANSIT':
            color = Colors.blue;
            width = 5;
            break;
          default:
            color = Colors.grey;
            width = 4;
        }

        final polyline = Polyline(
          polylineId: PolylineId('route_${i}_$travelMode'),
          points: polylineCoordinates,
          color: color,
          width: width,
          patterns: patterns,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        );

        polylines.add(polyline);
      }
    } catch (e) {
      print('Error creating route: $e');
      rethrow;
    }

    return polylines;
  }

  Future<List<Map<String, dynamic>>> searchNearbyBusStations(LatLng location,
      {double radius = 5000}) async {
    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/place/nearbysearch/json'
            '?location=${location.latitude},${location.longitude}'
            '&radius=$radius'
            '&type=bus_station'
            '&language=vi'
            '&key=$_apiKey');
    print(url);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results.map((place) {
            final location = place['geometry']['location'];
            return {
              'name': place['name'],
              'address': place['vicinity'],
              'location': LatLng(location['lat'], location['lng']),
              'rating': place['rating']?.toString() ?? 'N/A',
              'place_id': place['place_id'],
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching bus stations: $e');
      return [];
    }
  }
}
