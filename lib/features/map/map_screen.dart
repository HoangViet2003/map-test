import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'map_provider.dart';
import 'dart:math' show min, max;
import 'dart:async';

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

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(21.0000, 105.8500),
    zoom: 16,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
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
      print('Suggestions: $suggestions');

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

        // Clear suggestions after selection
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

  Widget _buildSearchField(bool isOrigin) {
    final suggestions = ref.watch(
        isOrigin ? originSuggestionsProvider : destinationSuggestionsProvider);
    final controller = isOrigin ? _originController : _destinationController;

    return Autocomplete<PlaceAutocomplete>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<PlaceAutocomplete>.empty();
        }
        _onSearchChanged(textEditingValue.text, isOrigin);
        return suggestions;
      },
      displayStringForOption: (PlaceAutocomplete option) => option.description,
      onSelected: (PlaceAutocomplete selection) {
        _selectPlace(selection, isOrigin);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: isOrigin ? 'Starting Point' : 'Destination',
            hintText:
                isOrigin ? 'Choose starting location' : 'Choose destination',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: isOrigin
                ? IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentLocation,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: Container(
              width:
                  MediaQuery.of(context).size.width - 32, // Account for padding
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option.mainText),
                    subtitle: Text(
                      option.secondaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;
      final mapService = ref.read(mapServiceProvider);
      final position = await mapService.getCurrentLocation();
      final location = LatLng(position.latitude, position.longitude);

      print('Current Location: $location');
      ref.read(currentLocationProvider.notifier).state = location;
      ref.read(originLocationProvider.notifier).state = location;

      final address = await mapService.getAddressFromCoordinates(location);
      _originController.text = address;
      print('Address: $address');

      _mapController?.animateCamera(CameraUpdate.newLatLng(location));
      _updateMarkers();
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state = e.toString();
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _updateRoute() async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;
      ref.read(errorMessageProvider.notifier).state = null;
      ref.read(polylineProvider.notifier).state = {};

      final origin = ref.read(originLocationProvider);
      final destination = ref.read(destinationLocationProvider);
      print('Origin: $origin');
      print('Destination: $destination');
      if (origin == null || destination == null) {
        ref.read(errorMessageProvider.notifier).state =
            'Please select both origin and destination';
        return;
      }

      final mapService = ref.read(mapServiceProvider);
      final polylines = await mapService.getPolylinePoints(origin, destination);

      if (polylines.isNotEmpty) {
        // Get all points from all polylines for bounds calculation
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

        setState(() {
          ref.read(polylineProvider.notifier).state = Set.from(polylines);
        });

        await _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
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
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: origin,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(
            title: 'Starting Point',
            snippet: 'Your journey begins here',
          ),
          onTap: () {
            print('Origin marker tapped');
          },
          draggable: true,
          onDragEnd: (newPosition) {
            ref.read(originLocationProvider.notifier).state = newPosition;
            _updateRoute();
          },
        ),
      );
    }

    if (destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Destination',
            snippet: 'Your journey ends here',
          ),
          onTap: () {
            print('Destination marker tapped');
          },
          draggable: true,
          onDragEnd: (newPosition) {
            ref.read(destinationLocationProvider.notifier).state = newPosition;
            _updateRoute();
          },
        ),
      );
    }

    ref.read(markersProvider.notifier).state = markers;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final errorMessage = ref.watch(errorMessageProvider);
    final markers = ref.watch(markersProvider);
    final polylines = ref.watch(polylineProvider);
    final isSearching = ref.watch(isSearchingProvider);

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
                    _buildSearchField(true),
                    const SizedBox(height: 12),
                    _buildSearchField(false),
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
          if (isLoading || isSearching)
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
    _debounce?.cancel();
    super.dispose();
  }
}
