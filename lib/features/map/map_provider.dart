import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_service.dart';

final mapServiceProvider = Provider((ref) => MapService());

final mapControllerProvider =
    StateProvider<GoogleMapController?>((ref) => null);

final currentLocationProvider = StateProvider<LatLng?>((ref) => null);

final originLocationProvider = StateProvider<LatLng?>((ref) => null);

final destinationLocationProvider = StateProvider<LatLng?>((ref) => null);

final markersProvider = StateProvider<Set<Marker>>((ref) => {});

final selectedMarkerProvider = StateProvider<Marker?>((ref) => null);

final polylineProvider = StateProvider<Set<Polyline>>((ref) => {});

final searchResultsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// Loading states
final isLoadingProvider = StateProvider<bool>((ref) => false);
final errorMessageProvider = StateProvider<String?>((ref) => null);
