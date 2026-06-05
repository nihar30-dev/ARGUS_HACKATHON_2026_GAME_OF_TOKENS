/// Model for creating a meeting request (POST payload) and reading it back
/// from the API (GET response includes id, sessionId, status, timestamps).
///
/// JSON key mapping:
///   objective          ↔  "meetingObjective"   (backend field name)
///   meetingDate        ↔  "createdAt"           (closest date field in entity)
class MeetingRequestModel {
  final String? id;
  final String? sessionId;
  final String organizationName;
  final String stakeholderRole;

  /// Maps to "meetingObjective" in the backend DTO/entity.
  final String objective;
  final String offeringDescription;

  /// Nullable — populated from "createdAt" when reading an existing request;
  /// not sent when creating a new one.
  final String? meetingDate;

  /// "PENDING" | "RUNNING" | "COMPLETED" | "FAILED"
  final String status;

  const MeetingRequestModel({
    this.id,
    this.sessionId,
    required this.organizationName,
    required this.stakeholderRole,
    required this.objective,
    required this.offeringDescription,
    this.meetingDate,
    this.status = 'PENDING',
  });

  // ── Deserialization ────────────────────────────────────────────────────────

  factory MeetingRequestModel.fromJson(Map<String, dynamic> j) =>
      MeetingRequestModel(
        id: j['id'] as String?,
        sessionId: j['sessionId'] as String?,
        organizationName: j['organizationName'] as String? ?? '',
        stakeholderRole: j['stakeholderRole'] as String? ?? '',
        objective: j['meetingObjective'] as String? ?? '',
        offeringDescription: j['offeringDescription'] as String? ?? '',
        meetingDate: j['createdAt'] as String?,
        status: j['status'] as String? ?? 'PENDING',
      );

  // ── Serialization ──────────────────────────────────────────────────────────

  /// POST body — only the four fields the backend @NotBlank-validates.
  Map<String, dynamic> toJson() => {
        'organizationName': organizationName,
        'meetingObjective': objective,
        'offeringDescription': offeringDescription,
        'stakeholderRole': stakeholderRole,
      };

  /// Full serialization including server-assigned fields (useful for caching).
  Map<String, dynamic> toFullJson() => {
        ...toJson(),
        if (id != null) 'id': id,
        if (sessionId != null) 'sessionId': sessionId,
        if (meetingDate != null) 'createdAt': meetingDate,
        'status': status,
      };

  // ── Helpers ────────────────────────────────────────────────────────────────

  MeetingRequestModel copyWith({
    String? id,
    String? sessionId,
    String? organizationName,
    String? stakeholderRole,
    String? objective,
    String? offeringDescription,
    String? meetingDate,
    String? status,
  }) =>
      MeetingRequestModel(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        organizationName: organizationName ?? this.organizationName,
        stakeholderRole: stakeholderRole ?? this.stakeholderRole,
        objective: objective ?? this.objective,
        offeringDescription: offeringDescription ?? this.offeringDescription,
        meetingDate: meetingDate ?? this.meetingDate,
        status: status ?? this.status,
      );

  bool get isPending => status == 'PENDING';
  bool get isRunning => status == 'RUNNING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';

  @override
  String toString() =>
      'MeetingRequestModel(org: $organizationName, status: $status)';
}
