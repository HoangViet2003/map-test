import 'package:flutter/material.dart';

class RouteSelectionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> routes;

  const RouteSelectionDialog({
    Key? key,
    required this.routes,
  }) : super(key: key);

  Widget _buildStepInfo(Map<String, dynamic> step) {
    final icon =
        _getTransitIcon(step['travel_mode'] as String, step['transit_details']);
    final details = _getStepDetails(step);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: icon,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(details.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (details.subtitle != null)
                  Text(
                    details.subtitle!,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
          if (step['duration'] != null)
            Text(
              step['duration']['text'],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _getTransitIcon(
      String travelMode, Map<String, dynamic>? transitDetails) {
    switch (travelMode) {
      case 'WALKING':
        return const Icon(Icons.directions_walk, size: 20);
      case 'TRANSIT':
        if (transitDetails != null) {
          final vehicle = transitDetails['line']['vehicle']['type']
              .toString()
              .toUpperCase();
          switch (vehicle) {
            case 'BUS':
              return const Icon(Icons.directions_bus, color: Colors.blue);
            case 'SUBWAY':
              return const Icon(Icons.subway, color: Colors.blue);
            case 'TRAIN':
              return const Icon(Icons.train, color: Colors.blue);
            default:
              return const Icon(Icons.directions_transit, color: Colors.blue);
          }
        }
        return const Icon(Icons.directions_transit);
      default:
        return const Icon(Icons.directions);
    }
  }

  ({String title, String? subtitle}) _getStepDetails(
      Map<String, dynamic> step) {
    final travelMode = step['travel_mode'] as String;

    if (travelMode == 'TRANSIT') {
      final transitDetails = step['transit_details'] as Map<String, dynamic>;
      final line = transitDetails['line'] as Map<String, dynamic>;
      final vehicle = line['vehicle']['type'].toString();
      final shortName = line['short_name'] ?? line['name'];
      final departure = transitDetails['departure_stop']['name'];
      final arrival = transitDetails['arrival_stop']['name'];

      return (
        title: '$vehicle ${shortName ?? ''}'.trim(),
        subtitle: 'From $departure to $arrival',
      );
    } else if (travelMode == 'WALKING') {
      final distance = step['distance']['text'];
      return (
        title: 'Walk ${distance}',
        subtitle: step['html_instructions']
            ?.toString()
            .replaceAll(RegExp(r'<[^>]*>'), ''),
      );
    }

    return (
      title: step['html_instructions']
              ?.toString()
              .replaceAll(RegExp(r'<[^>]*>'), '') ??
          'Unknown step',
      subtitle: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.directions_bus, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Available Routes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: routes.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final route = routes[index];
                final steps = route['steps'] as List;

                return InkWell(
                  onTap: () => Navigator.of(context).pop(route),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Route ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  route['duration']['text'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  route['distance']['text'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...steps.map((step) =>
                            _buildStepInfo(step as Map<String, dynamic>)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
