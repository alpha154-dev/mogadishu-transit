import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/stop.dart';
import '../models/route.dart';
import '../models/transfer.dart';
import '../models/alert.dart';

class DataService {
  List<Stop> stops = [];
  List<TransitRoute> routes = [];
  List<Transfer> transfers = [];
  List<TransitAlert> alerts = [];

  Future<void> loadAll() async {
    stops = await _loadStops();
    routes = await _loadRoutes();
    transfers = await _loadTransfers();
    alerts = await _loadAlerts();
  }

  Future<List<Stop>> _loadStops() async {
    final raw = await rootBundle.loadString('assets/data/stops.json');
    final List<dynamic> jsonList = jsonDecode(raw);
    return jsonList.map((e) => Stop.fromJson(e)).toList();
  }

  Future<List<TransitRoute>> _loadRoutes() async {
    final raw = await rootBundle.loadString('assets/data/routes.json');
    final List<dynamic> jsonList = jsonDecode(raw);
    return jsonList.map((e) => TransitRoute.fromJson(e)).toList();
  }

  Future<List<Transfer>> _loadTransfers() async {
    final raw = await rootBundle.loadString('assets/data/transfers.json');
    final List<dynamic> jsonList = jsonDecode(raw);
    return jsonList.map((e) => Transfer.fromJson(e)).toList();
  }

  Future<List<TransitAlert>> _loadAlerts() async {
    final raw = await rootBundle.loadString('assets/data/alerts.json');
    final List<dynamic> jsonList = jsonDecode(raw);
    return jsonList.map((e) => TransitAlert.fromJson(e)).toList();
  }
}