import 'package:flutter/material.dart';
import '../models/stop.dart';
import '../services/data_service.dart';

class StopDetailsScreen extends StatelessWidget {
  final Stop stop;
  final DataService dataService;

  const StopDetailsScreen({
    super.key,
    required this.stop,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    final servingRoutes = dataService.routes
        .where((route) => route.stops.contains(stop.id))
        .toList();

    final transferInfo = dataService.transfers
        .where((t) => t.stopId == stop.id)
        .toList();

    final isJunction = transferInfo.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(stop.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Latitude: ${stop.latitude}'),
                  Text('Longitude: ${stop.longitude}'),
                  if (isJunction) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz, size: 16, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text('Transfer Hub', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Routes serving this stop',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (servingRoutes.isEmpty)
            const Text('No routes found for this stop.')
          else
            for (final route in servingRoutes)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_bus),
                  title: Text(route.name),
                  subtitle: Text('Fare: \$${route.fare.toStringAsFixed(2)} • ${route.estimatedTime}'),
                ),
              ),
        ],
      ),
    );
  }
}
