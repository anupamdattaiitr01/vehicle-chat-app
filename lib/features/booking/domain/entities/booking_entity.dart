import 'package:equatable/equatable.dart';

class BookingEntity extends Equatable {
  final String id;
  final String managerId;
  final String managerName;
  final String driverId;
  final String roomId;
  final String passengerName;
  final String passengerPhone;
  final String pickupLocation;
  final String dropLocation;
  final String scheduledTime;
  final DateTime? scheduledAt;
  final DateTime? estimatedEndAt;
  final int durationMinutes;
  final String notes;
  final String status; // 'pending' | 'confirmed' | 'query_raised' | 'cancelled'
  final String queryMessage;
  final String createdAt;

  const BookingEntity({
    required this.id,
    required this.managerId,
    required this.managerName,
    required this.driverId,
    required this.roomId,
    required this.passengerName,
    required this.passengerPhone,
    required this.pickupLocation,
    required this.dropLocation,
    required this.scheduledTime,
    this.scheduledAt,
    this.estimatedEndAt,
    this.durationMinutes = 60,
    this.notes = '',
    this.status = 'pending',
    this.queryMessage = '',
    this.createdAt = '',
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isQueryRaised => status == 'query_raised';
  bool get isCancelled => status == 'cancelled';

  DateTime get sortTimestamp =>
      scheduledAt ?? DateTime.tryParse(createdAt) ?? DateTime.now();

  /// Strictly true only if the ride is active (not cancelled) and has not ended yet.
  bool get isUpcoming {
    if (isCancelled || scheduledAt == null) return false;
    final end = estimatedEndAt ??
        scheduledAt!.add(Duration(minutes: durationMinutes));
    return !end.isBefore(DateTime.now());
  }

  factory BookingEntity.fromMap(Map<String, dynamic> map) {
    final rawScheduledAt = map['scheduledAt']?.toString();
    final rawEstimatedEndAt = map['estimatedEndAt']?.toString();
    final parsedDuration =
        int.tryParse((map['durationMinutes'] ?? '60').toString()) ?? 60;

    final parsedStart = (rawScheduledAt != null && rawScheduledAt.isNotEmpty)
        ? DateTime.tryParse(rawScheduledAt)?.toLocal()
        : null;
    final parsedEnd =
    (rawEstimatedEndAt != null && rawEstimatedEndAt.isNotEmpty)
        ? DateTime.tryParse(rawEstimatedEndAt)?.toLocal()
        : parsedStart?.add(Duration(minutes: parsedDuration));

    return BookingEntity(
      id: (map['_id'] ?? map['bookingId'] ?? '').toString(),
      managerId: (map['managerId'] ?? '').toString(),
      managerName: (map['managerName'] ?? 'Manager').toString(),
      driverId: (map['driverId'] ?? '').toString(),
      roomId: (map['roomId'] ?? '').toString(),
      passengerName: (map['passengerName'] ?? 'Passenger').toString(),
      passengerPhone: (map['passengerPhone'] ?? '').toString(),
      pickupLocation: (map['pickupLocation'] ?? '').toString(),
      dropLocation: (map['dropLocation'] ?? '').toString(),
      scheduledTime: (map['scheduledTime'] ?? '').toString(),
      scheduledAt: parsedStart,
      estimatedEndAt: parsedEnd,
      durationMinutes: parsedDuration,
      notes: (map['notes'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      queryMessage: (map['queryMessage'] ?? '').toString(),
      createdAt: (map['createdAt'] ?? '').toString(),
    );
  }

  BookingEntity copyWith({
    String? status,
    String? queryMessage,
  }) {
    return BookingEntity(
      id: id,
      managerId: managerId,
      managerName: managerName,
      driverId: driverId,
      roomId: roomId,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      pickupLocation: pickupLocation,
      dropLocation: dropLocation,
      scheduledTime: scheduledTime,
      scheduledAt: scheduledAt,
      estimatedEndAt: estimatedEndAt,
      durationMinutes: durationMinutes,
      notes: notes,
      status: status ?? this.status,
      queryMessage: queryMessage ?? this.queryMessage,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    managerId,
    managerName,
    driverId,
    roomId,
    passengerName,
    passengerPhone,
    pickupLocation,
    dropLocation,
    scheduledTime,
    scheduledAt,
    estimatedEndAt,
    durationMinutes,
    notes,
    status,
    queryMessage,
    createdAt,
  ];
}