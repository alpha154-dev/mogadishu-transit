import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/data_service.dart';
import '../models/stop.dart';
import '../screens/stop_details_screen.dart';

class TransitMap extends StatelessWidget {
  final DataService dataService;
  final LatLng? userLocation;
  final MapController? mapController;
  final void Function()? onMapReady;

  const TransitMap({
    super.key,
    required this.dataService,
    this.userLocation,
    this.mapController,
    this.onMapReady,
  });

  Stop _stopById(String id) {
    return dataService.stops.firstWhere((s) => s.id == id);
  }

  Color _routeColor(String routeId) {
    switch (routeId) {
      case 'R1':
        return Colors.indigo;
      case 'R2':
        return Colors.teal;
      case 'R3':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stops = dataService.stops;
    final avgLat = stops.map((s) => s.latitude).reduce((a, b) => a + b) / stops.length;
    final avgLng = stops.map((s) => s.longitude).reduce((a, b) => a + b) / stops.length;

    final polylines = dataService.routes.map((route) {
      final points = route.stops.map((id) {
        final stop = _stopById(id);
        return LatLng(stop.latitude, stop.longitude);
      }).toList();
      return Polyline(points: points, color: _routeColor(route.id), strokeWidth: 4);
    }).toList();

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: userLocation ?? LatLng(avgLat, avgLng),
        initialZoom: 15,
        onMapReady: onMapReady,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mogadishu_transit',
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(
          markers: [
            ...stops.map((stop) {
              return Marker(
                point: LatLng(stop.latitude, stop.longitude),
                width: 36,
                height: 36,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StopDetailsScreen(stop: stop, dataService: dataService),
                      ),
                    );
                  },
                  child: const Icon(Icons.location_pin, color: Colors.black87, size: 30),
                ),
              );
            }),
            if (userLocation != null)
              Marker(
                point: userLocation!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.25),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: const Icon(Icons.my_location, color: Colors.blue, size: 22),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
