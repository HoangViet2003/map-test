import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../map_provider.dart';

class LocationSearchField extends ConsumerWidget {
  final bool isOrigin;
  final TextEditingController controller;
  final Function(String) onSearchChanged;
  final Function(PlaceAutocomplete) onPlaceSelected;
  final VoidCallback? onCurrentLocationPressed;
  final VoidCallback? onBusStationSearchPressed;
  final bool isBusStationMode;

  const LocationSearchField({
    Key? key,
    required this.isOrigin,
    required this.controller,
    required this.onSearchChanged,
    required this.onPlaceSelected,
    this.onCurrentLocationPressed,
    this.onBusStationSearchPressed,
    this.isBusStationMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(
        isOrigin ? originSuggestionsProvider : destinationSuggestionsProvider);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Autocomplete<PlaceAutocomplete>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<PlaceAutocomplete>.empty();
                  }
                  onSearchChanged(textEditingValue.text);
                  return suggestions;
                },
                displayStringForOption: (PlaceAutocomplete option) =>
                    option.description,
                onSelected: onPlaceSelected,
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: isOrigin ? 'Starting Point' : 'Destination',
                      hintText: isBusStationMode
                          ? 'Search for bus stations nearby'
                          : (isOrigin
                              ? 'Choose starting location'
                              : 'Choose destination'),
                      prefixIcon: Icon(isBusStationMode
                          ? Icons.directions_bus
                          : Icons.location_on),
                      suffixIcon: _buildSuffixIcon(),
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
                        width: MediaQuery.of(context).size.width -
                            80, // Adjusted width for the button
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
              ),
            ),
            if (onBusStationSearchPressed != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onBusStationSearchPressed,
                icon: Icon(
                  isBusStationMode ? Icons.location_on : Icons.directions_bus,
                  color: isBusStationMode ? Colors.blue : null,
                ),
                tooltip: isBusStationMode
                    ? 'Switch to location search'
                    : 'Search bus stations',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (isOrigin && onCurrentLocationPressed != null) {
      return IconButton(
        icon: const Icon(Icons.my_location),
        onPressed: onCurrentLocationPressed,
      );
    }
    return null;
  }
}
