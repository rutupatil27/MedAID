/// API payloads for volunteer tests.
Map<String, Object?> volunteerJson({
  String verificationStatus = 'APPROVED',
  String status = 'OFFLINE',
  bool profileCompleted = true,
  List<Map<String, Object?>> documents = const [],
}) => {
  'id': 'v1',
  'user': {'id': 'u1', 'name': 'Ravi Kale', 'email': 'ravi@example.com', 'username': 'ravi'},
  'profile': {'phone': '+91 98220 00000', 'city': 'Nashik'},
  'profileCompleted': profileCompleted,
  'verificationStatus': verificationStatus,
  'status': status,
  'location': null,
  'requiredDocuments': ['ID_PROOF', 'FIRST_AID_CERTIFICATE'],
  'documents': documents,
};

Map<String, Object?> dispatchedJson({
  String emergencyStatus = 'ASSIGNED',
  String assignmentStatus = 'PENDING',
}) => {
  'id': 'e1',
  'alertNumber': 'MED-20260917-0007',
  'status': emergencyStatus,
  'isOpen': emergencyStatus != 'RESOLVED',
  'location': {'latitude': 20.0086, 'longitude': 73.7925},
  'createdAt': DateTime.now().toUtc().toIso8601String(),
  'timeline': [
    {'status': 'CREATED', 'at': DateTime.now().toUtc().toIso8601String()},
  ],
  'assignment': {
    'id': 'a1',
    'status': assignmentStatus,
    'attemptNumber': 1,
    'dispatchedAt': DateTime.now().toUtc().toIso8601String(),
    'expiresAt': DateTime.now().add(const Duration(minutes: 2)).toUtc().toIso8601String(),
    'routeDistanceMeters': 420,
  },
  'reporter': {
    'name': 'Asha Patil',
    'phone': '+91 90000 00000',
    'medicalProfile': {'bloodGroup': 'O+', 'allergies': 'Penicillin'},
  },
};

/// `GET /volunteers/me/emergencies/:id/route` payload.
Map<String, Object?> routeJson({String source = 'ROUTING'}) => {
  'origin': {'latitude': 20.0140, 'longitude': 73.7925},
  'destination': {'latitude': 20.0086, 'longitude': 73.7925},
  'distanceMeters': 820,
  'durationSeconds': 690,
  'source': source,
  'geometry': [
    {'latitude': 20.0140, 'longitude': 73.7925},
    {'latitude': 20.0110, 'longitude': 73.7931},
    {'latitude': 20.0086, 'longitude': 73.7925},
  ],
  'computedAt': DateTime.now().toUtc().toIso8601String(),
};
