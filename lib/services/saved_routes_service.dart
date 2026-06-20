import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedRoute {
  final String originId;
  final String destinationId;
  final String originName;
  final String destinationName;

  SavedRoute({
    required this.originId,
    required this.destinationId,
    required this.originName,
    required this.destinationName,
  });

  Map<String, dynamic> toJson() => {
    'originId': originId,
    'destinationId': destinationId,
    'originName': originName,
    'destinationName': destinationName,
  };

  factory SavedRoute.fromJson(Map<String, dynamic> json) {
    return SavedRoute(
      originId: json['originId'] as String,
      destinationId: json['destinationId'] as String,
      originName: json['originName'] as String,
      destinationName: json['destinationName'] as String,
    );
  }
}

class SavedRoutesService {
  static const _storageKey = 'saved_routes';

  Future<List<SavedRoute>> getSavedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    return raw.map((s) => SavedRoute.fromJson(jsonDecode(s))).toList();
  }

  Future<void> saveRoute(SavedRoute route) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];

    // Avoid duplicate saves of the exact same origin/destination pair.
    final alreadySaved = existing.any((s) {
      final decoded = SavedRoute.fromJson(jsonDecode(s));
      return decoded.originId == route.originId && decoded.destinationId == route.destinationId;
    });
    if (alreadySaved) return;

    existing.add(jsonEncode(route.toJson()));
    await prefs.setStringList(_storageKey, existing);
  }

  Future<void> removeRoute(SavedRoute route) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];

    existing.removeWhere((s) {
      final decoded = SavedRoute.fromJson(jsonDecode(s));
      return decoded.originId == route.originId && decoded.destinationId == route.destinationId;
    });

    await prefs.setStringList(_storageKey, existing);
  }
}