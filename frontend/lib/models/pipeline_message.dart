/// Model returned by POST /api/meetings — pipeline starts asynchronously.
class MeetingStartResponse {
  final String meetingRequestId;
  final String organizationName;
  final String status;

  const MeetingStartResponse({
    required this.meetingRequestId,
    required this.organizationName,
    required this.status,
  });

  factory MeetingStartResponse.fromJson(Map<String, dynamic> j) =>
      MeetingStartResponse(
        meetingRequestId: (j['meetingRequestId'] ?? '').toString(),
        organizationName: j['organizationName'] as String? ?? '',
        status: j['status'] as String? ?? 'RUNNING',
      );
}
