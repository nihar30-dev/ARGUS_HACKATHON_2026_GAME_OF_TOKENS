class UserModel {
  final String userId;
  final String name;
  final String email;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        userId: j['userId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
      );
}

class AuthResponse {
  final String token;
  final String userId;
  final String name;
  final String email;

  const AuthResponse({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> j) => AuthResponse(
        token: j['token'] as String? ?? '',
        userId: j['userId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
      );
}

class UserMeeting {
  final String meetingRequestId;
  final String organizationName;
  final String? meetingObjective;
  final String? stakeholderRole;
  final String status;
  final DateTime? createdAt;
  final double? overallConfidence;

  const UserMeeting({
    required this.meetingRequestId,
    required this.organizationName,
    this.meetingObjective,
    this.stakeholderRole,
    required this.status,
    this.createdAt,
    this.overallConfidence,
  });

  factory UserMeeting.fromJson(Map<String, dynamic> j) => UserMeeting(
        meetingRequestId: (j['meetingRequestId'] ?? '').toString(),
        organizationName: j['organizationName'] as String? ?? '',
        meetingObjective: j['meetingObjective'] as String?,
        stakeholderRole: j['stakeholderRole'] as String?,
        status: j['status'] as String? ?? 'UNKNOWN',
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
        overallConfidence: (j['overallConfidence'] as num?)?.toDouble(),
      );
}
