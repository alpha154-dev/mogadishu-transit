class TransitRoute {
  final String id;
  final String name;
  final String from;
  final String to;
  final double fare;
  final String estimatedTime;
  final List<String> stops;

  TransitRoute({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    required this.fare,
    required this.estimatedTime,
    required this.stops,
  });

  factory TransitRoute.fromJson(Map<String, dynamic> json) {
    return TransitRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      fare: (json['fare'] as num).toDouble(),
      estimatedTime: json['estimatedTime'] as String,
      stops: List<String>.from(json['stops'] as List),
    );
  }
}