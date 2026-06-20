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
      appBar: AppBar(title: const Text('Saved Routes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No saved routes yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Plan a trip and save it to see it here',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: _routes.length,
                  itemBuilder: (context, index) {
                    final route = _routes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.directions_bus,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          route.originName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(Icons.arrow_downward, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                route.destinationName,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => widget.onRouteSelected(route),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
                          onPressed: () => _delete(route),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
