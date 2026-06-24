# Mogadishu Transit

A Flutter app for navigating public transit in Mogadishu — browse bus stops, plan trips, and save your favourite routes.

## Features

- **Transit map** — interactive map showing all stops and route lines
- **Trip planner** — enter origin and destination to find the best route, including transfers
- **Saved routes** — bookmark routes you use often for quick access
- **Service alerts** — real-time notices about delays or route changes

## Getting started

**Prerequisites**: Flutter 3.x with Dart SDK ^3.12.1

```bash
flutter pub get
flutter run
```

## Project structure

```
lib/
  models/        # Stop, Route, Transfer, Alert data classes
  services/      # DataService, RoutingService, LocationService, SavedRoutesService
  screens/       # HomeScreen, TripPlannerScreen, StopDetailsScreen, SavedRoutesScreen
  widgets/       # TransitMap widget
assets/data/     # stops.json, routes.json, transfers.json, alerts.json
```

## Dependencies

| Package | Purpose |
|---|---|
| `flutter_map` | Tile-based interactive map |
| `geolocator` | Device GPS for current location |
| `latlong2` | Lat/lng coordinate types |
| `shared_preferences` | Persisting saved routes locally |
