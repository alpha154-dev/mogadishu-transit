import 'package:flutter/material.dart';
import '../services/saved_routes_service.dart';

class SavedRoutesScreen extends StatefulWidget {
  final void Function(SavedRoute route) onRouteSelected;
  final int reloadKey;

  const SavedRoutesScreen({
    super.key,
    required this.onRouteSelected,
    this.reloadKey = 0,
  });

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  final SavedRoutesService _service = SavedRoutesService();
  List<SavedRoute> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SavedRoutesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reloadKey != oldWidget.reloadKey) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final routes = await _service.getSavedRoutes();
    setState(() {
      _routes = routes;
      _loading = false;
    });
  }

  Future<void> _delete(SavedRoute route) async {
    await _service.removeRoute(route);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Routes', style: TextStyle(color: Colors.white)),
      backgroundColor:Colors.green,
      centerTitle: true,),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
          ? const Center(child: Text('No saved routes yet.'))
          : ListView.builder(
        itemCount: _routes.length,
        itemBuilder: (context, index) {
          final route = _routes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primary),
              title: Text('${route.originName} → ${route.destinationName}'),
              onTap: () => widget.onRouteSelected(route),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(route),
              ),
            ),
          );
        },
      ),
    );
  }
}
