import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapService {
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
