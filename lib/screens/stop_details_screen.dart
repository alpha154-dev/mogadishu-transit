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
                  const SizedBox(height: 10),
                  _coordRow(Icons.north, 'Lat', stop.latitude.toStringAsFixed(5)),
                  const SizedBox(height: 4),
                  _coordRow(Icons.east, 'Lng', stop.longitude.toStringAsFixed(5)),
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
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.directions_bus,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(route.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(route.estimatedTime),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$${route.fare.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _coordRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text('$label  ', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        Text(value, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
      ],
    );
  }
}