import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_service.dart';

final mapServiceProvider = Provider<MapService>((ref) => MapService());

final currentLocationProvider = StateProvider<LatLng?>((ref) => null);
final originLocationProvider = StateProvider<LatLng?>((ref) => null);
final destinationLocationProvider = StateProvider<LatLng?>((ref) => null);

final originSuggestionsProvider =
    StateProvider<List<PlaceAutocomplete>>((ref) => []);
final destinationSuggestionsProvider =
    StateProvider<List<PlaceAutocomplete>>((ref) => []);

final isLoadingProvider = StateProvider<bool>((ref) => false);
final isSearchingProvider = StateProvider<bool>((ref) => false);
final errorMessageProvider = StateProvider<String?>((ref) => null);

final markersProvider = StateProvider<Set<Marker>>((ref) => {});
final polylineProvider = StateProvider<Set<Polyline>>((ref) => {});

final isBusStationModeProvider = StateProvider<bool>((ref) => false);
final busStationsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

class PlaceAutocomplete {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;

  PlaceAutocomplete({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
  });

  factory PlaceAutocomplete.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'];
    return PlaceAutocomplete(
      placeId: json['place_id'],
      mainText: structuredFormatting['main_text'],
      secondaryText: structuredFormatting['secondary_text'],
      description: json['description'],
    );
  }
}
