import '../models/route.dart';

class RouteStep {
  final String routeId;
  final String routeName;
  final List<String> stopIds;
  final double fare;

  RouteStep({
    required this.routeId,
    required this.routeName,
    required this.stopIds,
    required this.fare,
  });
}

class TripResult {
  final List<RouteStep> steps;
  final double totalFare;

  TripResult({required this.steps, required this.totalFare});

  bool get isDirect => steps.length == 1;
}

class RoutingService {
  final List<TransitRoute> routes;

  RoutingService(this.routes);

  /// Finds a path from [originStopId] to [destinationStopId].
  /// Returns null if no path found within maxTransfers.
  TripResult? findTrip(String originStopId, String destinationStopId, {int maxTransfers = 2}) {
    // BFS over routes, since transfers are limited (small system, BFS is fine
    // and simpler/more predictable than Dijkstra given we lack per-segment time data).

    // Each BFS node = (current stop, path of RouteSteps taken so far)
    final queue = <_BfsNode>[];

    // Start: find every route that contains the origin stop
    for (final route in routes) {
      if (route.stops.contains(originStopId)) {
        queue.add(_BfsNode(
          currentStop: originStopId,
          stepsSoFar: [],
        ));
      }
    }

    // Direct check first: any single route containing both origin and destination
    for (final route in routes) {
      if (route.stops.contains(originStopId) && route.stops.contains(destinationStopId)) {
        return TripResult(
          steps: [
            RouteStep(
              routeId: route.id,
              routeName: route.name,
              stopIds: _sliceStops(route.stops, originStopId, destinationStopId),
              fare: route.fare,
            )
          ],
          totalFare: route.fare,
        );
      }
    }

    // BFS for transfers (1 or 2 hops)
    final initialQueue = <_BfsNode>[
      _BfsNode(currentStop: originStopId, stepsSoFar: [])
    ];

    var frontier = initialQueue;
    final visited = <String>{originStopId};

    for (int hop = 0; hop < maxTransfers; hop++) {
      final nextFrontier = <_BfsNode>[];

      for (final node in frontier) {
        // find all routes touching current stop
        for (final route in routes) {
          if (!route.stops.contains(node.currentStop)) continue;
          // skip route already used in this path (no immediate re-use of same route)
          if (node.stepsSoFar.any((s) => s.routeId == route.id)) continue;

          // check if destination is on this route
          if (route.stops.contains(destinationStopId)) {
            final newStep = RouteStep(
              routeId: route.id,
              routeName: route.name,
              stopIds: _sliceStops(route.stops, node.currentStop, destinationStopId),
              fare: route.fare,
            );
            final allSteps = [...node.stepsSoFar, newStep];
            final totalFare = allSteps.fold(0.0, (sum, s) => sum + s.fare);
            return TripResult(steps: allSteps, totalFare: totalFare);
          }

          // otherwise, explore other stops on this route as potential transfer points
          for (final stop in route.stops) {
            if (visited.contains(stop)) continue;
            visited.add(stop);
            final newStep = RouteStep(
              routeId: route.id,
              routeName: route.name,
              stopIds: _sliceStops(route.stops, node.currentStop, stop),
              fare: route.fare,
            );
            nextFrontier.add(_BfsNode(
              currentStop: stop,
              stepsSoFar: [...node.stepsSoFar, newStep],
            ));
          }
        }
      }

      frontier = nextFrontier;
    }

    return null; // no path found within maxTransfers
  }

  /// Returns the sublist of stops between [from] and [to], inclusive,
  /// regardless of which order they appear in the route (routes are bidirectional).
  List<String> _sliceStops(List<String> stops, String from, String to) {
    final fromIndex = stops.indexOf(from);
    final toIndex = stops.indexOf(to);
    if (fromIndex <= toIndex) {
      return stops.sublist(fromIndex, toIndex + 1);
    } else {
      return stops.sublist(toIndex, fromIndex + 1).reversed.toList();
    }
  }
}

class _BfsNode {
  final String currentStop;
  final List<RouteStep> stepsSoFar;

  _BfsNode({required this.currentStop, required this.stepsSoFar});
}