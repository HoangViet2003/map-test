import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'map_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(21.0000, 105.8500),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
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

  Future<void> _searchLocation(String query, bool isOrigin) async {
    if (query.isEmpty) return;

    try {
      ref.read(isLoadingProvider.notifier).state = true;
      final mapService = ref.read(mapServiceProvider);
      final locations = await mapService.getCoordinatesFromAddress(query);

      if (locations.isNotEmpty) {
        final location =
            LatLng(locations.first.latitude, locations.first.longitude);
        if (isOrigin) {
          ref.read(originLocationProvider.notifier).state = location;
          print('Set origin: $location');
        } else {
          ref.read(destinationLocationProvider.notifier).state = location;
          print('Set destination: $location');
        }

        _mapController?.animateCamera(CameraUpdate.newLatLng(location));
        _updateMarkers();
      }
    } catch (e) {
      print('Error searching location: $e');
      ref.read(errorMessageProvider.notifier).state = e.toString();
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _updateRoute() async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;
      ref.read(errorMessageProvider.notifier).state = null;
      print('Updating route...');

      final origin = ref.read(originLocationProvider);
      final destination = ref.read(destinationLocationProvider);
      print('Origin: $origin');
      print('Destination: $destination');

      if (origin == null || destination == null) {
        ref.read(errorMessageProvider.notifier).state =
            'Please select both origin and destination';
        return;
      }

      ref.read(polylineProvider.notifier).state = {};

      final mapService = ref.read(mapServiceProvider);
      final points = await mapService.getPolylinePoints(origin, destination);
      print('Route points: ${points.length}');

      if (points.isNotEmpty) {
        print('Creating polyline...');
        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Colors.blue,
          width: 5,
          visible: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        );

        ref.read(polylineProvider.notifier).state = {polyline};
        print('Polyline set updated');

        final bounds = LatLngBounds(
          southwest: LatLng(
            points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b) -
                0.01,
            points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b) -
                0.01,
          ),
          northeast: LatLng(
            points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b) +
                0.01,
            points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b) +
                0.01,
          ),
        );

        await _mapController
            ?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      } else {
        ref.read(errorMessageProvider.notifier).state =
            'Could not find a route between these locations';
      }
    } catch (e) {
      print('Error updating route: $e');
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

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final errorMessage = ref.watch(errorMessageProvider);
    final markers = ref.watch(markersProvider);
    final polylines = ref.watch(polylineProvider);
    print('Current polylines: ${polylines.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      controller: _originController,
                      decoration: InputDecoration(
                        labelText: 'Starting Point',
                        hintText: 'Choose starting location',
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: _getCurrentLocation,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onSubmitted: (value) => _searchLocation(value, true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        hintText: 'Choose destination',
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_location),
                          onPressed: () {
                            _destinationController.text = 'Times City';
                            _searchLocation('Times City', false);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onSubmitted: (value) => _searchLocation(value, false),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final origin = ref.read(originLocationProvider);
                          final destination =
                              ref.read(destinationLocationProvider);

                          if (origin != null && destination != null) {
                            await _updateRoute();
                          } else {
                            ref.read(errorMessageProvider.notifier).state =
                                'Please ensure both locations are selected';
                          }
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Show Route'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: _initialPosition,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    print('Map controller created');
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  markers: markers,
                  polylines: polylines,
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (errorMessage != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}