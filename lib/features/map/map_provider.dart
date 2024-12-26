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

// Autocomplete providers
final originSuggestionsProvider =
    StateProvider<List<PlaceAutocomplete>>((ref) => []);
final destinationSuggestionsProvider =
    StateProvider<List<PlaceAutocomplete>>((ref) => []);
final isSearchingProvider = StateProvider<bool>((ref) => false);

// Loading states
final isLoadingProvider = StateProvider<bool>((ref) => false);
final errorMessageProvider = StateProvider<String?>((ref) => null);

// Place Autocomplete class
class PlaceAutocomplete {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceAutocomplete({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceAutocomplete.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] ?? {};
    return PlaceAutocomplete(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structured['main_text'] ?? '',
      secondaryText: structured['secondary_text'] ?? '',
    );
  }
}
