import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/stop.dart';
import '../models/alert.dart';
import '../services/data_service.dart';
import '../services/routing_service.dart';
import '../services/location_service.dart';
import '../services/saved_routes_service.dart';
import '../widgets/transit_map.dart';

class TripPlannerScreen extends StatefulWidget {
  final DataService dataService;
  final SavedRoute? pendingRoute;
  final void Function() onPendingRouteConsumed;

  const TripPlannerScreen({
    super.key,
    required this.dataService,
    this.pendingRoute,
    required this.onPendingRouteConsumed,
  });

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  String? _originId;
  String? _destinationId;
  TripResult? _result;
  String _statusMessage = '';
  bool _showOriginField = false;
  bool _hintShown = false;
  bool _showHintBubble = false;

  final SavedRoutesService _savedRoutesService = SavedRoutesService();

  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  bool _mapReady = false;
  Position? _currentPosition;
  Stop? _nearestStop;
  double? _nearestStopDistance;
  String _locationStatus = '';
  bool _detectingLocation = false;

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _detectNearestStop();
    _applyPendingRoute(widget.pendingRoute);
  }

  @override
  void didUpdateWidget(TripPlannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pendingRoute != null && widget.pendingRoute != oldWidget.pendingRoute) {
      _applyPendingRoute(widget.pendingRoute);
    }
  }

  void _applyPendingRoute(SavedRoute? route) {
    if (route == null) return;
    setState(() {
      _originId = route.originId;
      _destinationId = route.destinationId;
      _originController.text = route.originName;
      _destinationController.text = route.destinationName;
      _showOriginField = true;
      _result = null;
      _statusMessage = '';
    });
    widget.onPendingRouteConsumed();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _detectNearestStop() async {
    setState(() {
      _detectingLocation = true;
      _locationStatus = '';
    });

    try {
      final position = await _locationService.getCurrentPosition();
      final nearest = _locationService.findNearestStop(position, widget.dataService.stops);

      setState(() {
        _currentPosition = position;
        _nearestStop = nearest.stop;
        _nearestStopDistance = nearest.distanceMeters;
        _originId = nearest.stop.id;
        _originController.text = nearest.stop.name;
        _detectingLocation = false;
      });

      if (_mapReady) {
        _mapController.move(LatLng(position.latitude, position.longitude), 15);
      }

      _showStopHintOnce();
    } catch (e) {
      setState(() {
        _locationStatus = 'Could not detect location: ${e.toString()}';
        _detectingLocation = false;
        _showOriginField = true;
      });
    }
  }

  void _showStopHintOnce() {
    if (_hintShown) return;
    _hintShown = true;
    setState(() => _showHintBubble = true);
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showHintBubble = false);
    });
  }

  Future<void> _saveCurrentRoute() async {
    if (_originId == null || _destinationId == null) return;
    await _savedRoutesService.saveRoute(SavedRoute(
      originId: _originId!,
      destinationId: _destinationId!,
      originName: _stopName(_originId!),
      destinationName: _stopName(_destinationId!),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route saved.'), duration: Duration(seconds: 1)),
      );
    }
  }

  Widget _buildStopSearchField({
    required String label,
    required List<Stop> stops,
    required String? selectedId,
    required void Function(String?) onSelectedIdChanged,
    TextEditingController? controller,
  }) {
    return Autocomplete<Stop>(
      displayStringForOption: (stop) => stop.name,
      optionsBuilder: (TextEditingValue textValue) {
        if (textValue.text.isEmpty) return const Iterable<Stop>.empty();
        final query = textValue.text.toLowerCase();
        return stops.where((stop) => stop.name.toLowerCase().contains(query));
      },
      onSelected: (stop) => onSelectedIdChanged(stop.id),
      fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
        if (controller != null && fieldController.text != controller.text) {
          fieldController.text = controller.text;
        }

        fieldController.addListener(() {
          final matches = stops.any((s) => s.name == fieldController.text);
          if (!matches && selectedId != null) {
            onSelectedIdChanged(null);
          }
          if (controller != null && controller.text != fieldController.text) {
            controller.text = fieldController.text;
          }
        });

        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(label == 'From' ? Icons.trip_origin : Icons.place),
            border: const OutlineInputBorder(),
          ),
        );
      },
    );
  }

  void _findTrip() {
    if (_originId == null || _destinationId == null) {
      setState(() {
        _statusMessage = 'Pick both an origin and a destination.';
        _result = null;
      });
      return;
    }
    if (_originId == _destinationId) {
      setState(() {
        _statusMessage = 'Origin and destination can\'t be the same stop.';
        _result = null;
      });
      return;
    }

    final routingService = RoutingService(widget.dataService.routes);
    final trip = routingService.findTrip(_originId!, _destinationId!);

    setState(() {
      _result = trip;
      _statusMessage = trip == null ? 'No route found between those stops.' : '';
    });
  }

  String _stopName(String id) {
    return widget.dataService.stops.firstWhere((s) => s.id == id).name;
  }

  List<TransitAlert> _alertsForStep(RouteStep step) {
    return widget.dataService.alerts.where((alert) {
      if (!alert.routes.contains(step.routeId)) return false;
      if (alert.status != 'Active') return false;

      final matchingStop = widget.dataService.stops
          .where((s) => s.name == alert.location)
          .toList();
      if (matchingStop.isEmpty) return false;

      return step.stopIds.contains(matchingStop.first.id);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.dataService.stops;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mogadishu Transit'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: TransitMap(
              dataService: widget.dataService,
              mapController: _mapController,
              onMapReady: () {
                _mapReady = true;
                if (_currentPosition != null) {
                  _mapController.move(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    15,
                  );
                }
              },
              userLocation: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : null,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_detectingLocation)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Finding your location...'),
                              ],
                            ),
                          ),
                        if (_locationStatus.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(_locationStatus, style: const TextStyle(color: Colors.grey)),
                          ),
                        if (_showOriginField) ...[
                          _buildStopSearchField(
                            label: 'From',
                            stops: stops,
                            selectedId: _originId,
                            onSelectedIdChanged: (id) => setState(() => _originId = id),
                            controller: _originController,
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: _buildStopSearchField(
                                label: 'Where do you want to go?',
                                stops: stops,
                                selectedId: _destinationId,
                                onSelectedIdChanged: (id) => setState(() => _destinationId = id),
                                controller: _destinationController,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: _showOriginField
                                  ? 'Hide starting point'
                                  : 'Choose a different starting point',
                              icon: Icon(
                                Icons.edit_location_alt_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () {
                                setState(() => _showOriginField = !_showOriginField);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _findTrip,
                          icon: const Icon(Icons.search),
                          label: const Text('Find Trip'),
                        ),
                        if (_statusMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _statusMessage,
                                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: _buildResult(_result!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!_showOriginField && _nearestStop != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  elevation: 4,
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                    title: Text(
                      'Starting from: ${_nearestStop!.name}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          if (_showHintBubble)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: CustomPaint(
                  painter: _BubbleTailPainter(color: Theme.of(context).colorScheme.primary),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_pin, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Black markers show bus stops — tap one for details.',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResult(TripResult result) {
    return ListView(
      children: [
        Row(
          children: [
            Icon(
              result.isDirect ? Icons.directions_bus : Icons.transfer_within_a_station,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              result.isDirect ? 'Direct route' : '${result.steps.length - 1} transfer(s)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final step in result.steps) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_bus, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(step.routeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\$${step.fare.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.stopIds.map(_stopName).join(' → '),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  for (final alert in _alertsForStep(step))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${alert.title} — ${alert.location}',
                                style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const Divider(height: 8),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total fare', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(
              '\$${result.totalFare.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _saveCurrentRoute,
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('Save this route'),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path();
    const tailWidth = 16.0;
    const tailHeight = 10.0;
    final startX = size.width / 2 - tailWidth / 2;
    path.moveTo(startX, size.height - tailHeight);
    path.lineTo(startX + tailWidth / 2, size.height);
    path.lineTo(startX + tailWidth, size.height - tailHeight);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}