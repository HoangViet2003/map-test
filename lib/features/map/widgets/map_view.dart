import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../map_provider.dart';

class MapView extends ConsumerWidget {
  final void Function(GoogleMapController) onMapCreated;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const MapView({
    Key? key,
    required this.onMapCreated,
    required this.markers,
    required this.polylines,
  }) : super(key: key);

  static const CameraPosition initialPosition = CameraPosition(
    target: LatLng(21.0000, 105.8500),
    zoom: 16,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: initialPosition,
      onMapCreated: onMapCreated,
      markers: markers,
      polylines: polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}
