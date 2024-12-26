import 'package:flutter/material.dart';

class RouteSelectionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> routes;

  const RouteSelectionDialog({
    Key? key,
    required this.routes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Available Routes'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final route = routes[index];
            return ListTile(
              title: Text('Route ${index + 1}: ${route['summary']}'),
              subtitle: Text('${route['distance']} • ${route['duration']}'),
              onTap: () => Navigator.of(context).pop(route),
            );
          },
        ),
      ),
    );
  }
}
