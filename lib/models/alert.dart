class TransitAlert {
  final String id;
  final String title;
  final String location;
  final List<String> routes;
  final String status;

  TransitAlert({
    required this.id,
    required this.title,
    required this.location,
    required this.routes,
    required this.status,
  });

  factory TransitAlert.fromJson(Map<String, dynamic> json) {
    return TransitAlert(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      routes: List<String>.from(json['routes'] as List),
      status: json['status'] as String,
    );
  }
}