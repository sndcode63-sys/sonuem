class VehicleHistory {
  final int? eventId;
  final String? eventName;
  final DateTime? eventDate;
  final double? hours;
  final double? miles;
  final String? comments;
  final String? user;
  final int? vehicleId;

  VehicleHistory({
    this.eventId,
    this.eventName,
    this.eventDate,
    this.hours,
    this.miles,
    this.comments,
    this.user,
    this.vehicleId,
  });

  factory VehicleHistory.fromJson(Map<String, dynamic> json) {
    return VehicleHistory(
      eventId:   json['eventId'],
      eventName: json['eventName'],
      eventDate: json['eventDate'] != null
          ? DateTime.tryParse(json['eventDate'])
          : null,
      hours:    (json['hours'] as num?)?.toDouble(),
      miles:    (json['miles'] as num?)?.toDouble(),
      comments: json['comments'],
      user:     json['user'],
      vehicleId: json['vehicleId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "eventId":   eventId,
      "eventName": eventName ?? "",
      "eventDate": eventDate?.toUtc().toIso8601String(),
      "hours":     hours ?? 0.0,
      "miles":     miles ?? 0.0,
      "comments":  comments ?? "",
      "user":      user ?? "",
      "vehicleId": vehicleId,
    };
  }
}