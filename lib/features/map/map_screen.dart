import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'map_provider.dart';
import 'widgets/location_search_field.dart';
import 'widgets/map_view.dart';
import 'widgets/route_selection_dialog.dart';
import 'dart:async';
import 'dart:math' show min, max;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, bool isOrigin) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchLocation(query, isOrigin);
    });
  }

  Future<void> _searchLocation(String query, bool isOrigin) async {
    if (query.isEmpty) {
      ref
          .read(isOrigin
              ? originSuggestionsProvider.notifier
              : destinationSuggestionsProvider.notifier)
          .state = [];
      return;
    }

    try {
      ref.read(isSearchingProvider.notifier).state = true;
      final mapService = ref.read(mapServiceProvider);
      final suggestions = await mapService.getPlaceSuggestions(query);

      if (isOrigin) {
        ref.read(originSuggestionsProvider.notifier).state = suggestions;
      } else {
        ref.read(destinationSuggestionsProvider.notifier).state = suggestions;
      }
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = e.toString();
    } finally {
      ref.read(isSearchingProvider.notifier).state = false;
    }
  }

  Future<void> _selectPlace(PlaceAutocomplete place, bool isOrigin) async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;
      final mapService = ref.read(mapServiceProvider);
      final location = await mapService.getPlaceDetails(place.placeId);

      if (location != null) {
        if (isOrigin) {
          ref.read(originLocationProvider.notifier).state = location;
          _originController.text = place.description;
        } else {
          ref.read(destinationLocationProvider.notifier).state = location;
          _destinationController.text = place.description;
        }

        _mapController?.animateCamera(CameraUpdate.newLatLng(location));
        _updateMarkers();

        ref
            .read(isOrigin
                ? originSuggestionsProvider.notifier
                : destinationSuggestionsProvider.notifier)
            .state = [];
      }
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = e.toString();
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;
      final mapService = ref.read(mapServiceProvider);
      final position = await mapService.getCurrentLocation();
      final location = LatLng(position.latitude, position.longitude);

      ref.read(currentLocationProvider.notifier).state = location;
      ref.read(originLocationProvider.notifier).state = location;

      final address = await mapService.getAddressFromCoordinates(location);
      _originController.text = address;

      _mapController?.animateCamera(CameraUpdate.newLatLng(location));
      _updateMarkers();
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = e.toString();
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  void _updateMarkers() {
    final origin = ref.read(originLocationProvider);
    final destination = ref.read(destinationLocationProvider);
    final markers = <Marker>{};

    if (origin != null) {
      markers.add(Marker(
        markerId: const MarkerId('origin'),
        position: origin,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (destination != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    ref.read(markersProvider.notifier).state = markers;
  }

  Future<void> _updateRoute() async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;
      ref.read(errorMessageProvider.notifier).state = null;
      ref.read(polylineProvider.notifier).state = {};

      final origin = ref.read(originLocationProvider);
      final destination = ref.read(destinationLocationProvider);

      if (origin == null || destination == null) {
        ref.read(errorMessageProvider.notifier).state =
            'Please select both origin and destination';
        return;
      }

      final mapService = ref.read(mapServiceProvider);
      final routes = await mapService.getPossibleRoutes(origin, destination);

      if (routes.isNotEmpty) {
        if (!mounted) return;

        final selectedRoute = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => RouteSelectionDialog(routes: routes),
        );

        if (selectedRoute != null) {
          final polylines =
              await mapService.getPolylineFromRoute(selectedRoute);
          ref.read(polylineProvider.notifier).state =
              Set<Polyline>.from(polylines);

          if (polylines.isNotEmpty) {
            final allPoints =
                polylines.expand((polyline) => polyline.points).toList();
            final bounds = LatLngBounds(
              southwest: LatLng(
                allPoints.map((p) => p.latitude).reduce(min),
                allPoints.map((p) => p.longitude).reduce(min),
              ),
              northeast: LatLng(
                allPoints.map((p) => p.latitude).reduce(max),
                allPoints.map((p) => p.longitude).reduce(max),
              ),
            );

            _mapController
                ?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
          }
        }
      }
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = e.toString();
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _toggleBusStationMode() async {
    final isBusStationMode = ref.read(isBusStationModeProvider);
    ref.read(isBusStationModeProvider.notifier).state = !isBusStationMode;

    if (!isBusStationMode) {
      // Switching to bus station mode
      await _searchBusStationsNearby();
    } else {
      // Switching back to normal mode
      ref.read(busStationsProvider.notifier).state = [];
      _updateMarkers(); // Reset to normal markers
    }
  }

  Future<void> _searchBusStationsNearby() async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;
      final mapService = ref.read(mapServiceProvider);

      LatLng searchLocation;
      if (_mapController != null) {
        // Get the center of the current map view
        final position = await _mapController!.getVisibleRegion();
        searchLocation = LatLng(
          (position.northeast.latitude + position.southwest.latitude) / 2,
          (position.northeast.longitude + position.southwest.longitude) / 2,
        );
      } else {
        // Fallback to current location if map is not ready
        final currentLocation = ref.read(currentLocationProvider);
        if (currentLocation == null) {
          ref.read(errorMessageProvider.notifier).state =
              'Current location not available';
          return;
        }
        searchLocation = currentLocation;
      }

      final busStations =
          await mapService.searchNearbyBusStations(searchLocation);
      ref.read(busStationsProvider.notifier).state = busStations;

      if (busStations.isEmpty) {
        ref.read(errorMessageProvider.notifier).state =
            'No bus stations found nearby';
        return;
      }

      // Update markers with bus stations
      final markers = <Marker>{};
      for (final station in busStations) {
        markers.add(
          Marker(
            markerId: MarkerId(station['place_id']),
            position: station['location'],
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: station['name'],
              snippet: station['address'],
            ),
          ),
        );
      }
      ref.read(markersProvider.notifier).state = markers;

      // Adjust map bounds to show all bus stations
      if (busStations.length > 1) {
        final points = busStations.map((s) => s['location'] as LatLng).toList();
        final bounds = LatLngBounds(
          southwest: LatLng(
            points.map((p) => p.latitude).reduce(min),
            points.map((p) => p.longitude).reduce(min),
          ),
          northeast: LatLng(
            points.map((p) => p.latitude).reduce(max),
            points.map((p) => p.longitude).reduce(max),
          ),
        );
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = e.toString();
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = ref.watch(markersProvider);
    final polylines = ref.watch(polylineProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final errorMessage = ref.watch(errorMessageProvider);
    final isBusStationMode = ref.watch(isBusStationModeProvider);

    return Scaffold(
      body: Stack(
        children: [
          MapView(
            onMapCreated: (controller) => _mapController = controller,
            markers: markers,
            polylines: polylines,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LocationSearchField(
                            isOrigin: true,
                            controller: _originController,
                            onSearchChanged: (query) =>
                                _onSearchChanged(query, true),
                            onPlaceSelected: (place) =>
                                _selectPlace(place, true),
                            onCurrentLocationPressed: _getCurrentLocation,
                            onBusStationSearchPressed: _toggleBusStationMode,
                            isBusStationMode: isBusStationMode,
                          ),
                          if (!isBusStationMode) ...[
                            const SizedBox(height: 16),
                            LocationSearchField(
                              isOrigin: false,
                              controller: _destinationController,
                              onSearchChanged: (query) =>
                                  _onSearchChanged(query, false),
                              onPlaceSelected: (place) =>
                                  _selectPlace(place, false),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _updateRoute,
                                child: const Text('Find Route'),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _searchBusStationsNearby,
                                icon: const Icon(Icons.directions_bus),
                                label: const Text('Find Bus Stations Nearby'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Showing ${ref.watch(busStationsProvider).length} bus stations',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (errorMessage != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.red,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
