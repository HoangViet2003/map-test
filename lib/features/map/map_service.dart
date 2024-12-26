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

    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=$input'
            '&components=country:vn'
            '&language=vi'
            '&types=geocode|establishment'
            '&key=$_apiKey');

    try {
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
}
