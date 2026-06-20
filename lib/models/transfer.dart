class Transfer {
  final String id;
  final String stopId;
  final String name;
  final String type;
  final List<String> connectedRoutes;

  Transfer({
    required this.id,
    required this.stopId,
    required this.name,
    required this.type,
    required this.connectedRoutes,
  });

  factory Transfer.fromJson(Map<String, dynamic> json) {
    return Transfer(
      id: json['id'] as String,
      stopId: json['stopId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      connectedRoutes: List<String>.from(json['connectedRoutes'] as List),
    );
  }
}