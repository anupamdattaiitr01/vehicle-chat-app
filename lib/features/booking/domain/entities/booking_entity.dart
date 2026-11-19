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
  final String notes;
  final String status; // 'pending' | 'confirmed' | 'query_raised'
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
    this.notes = '',
    this.status = 'pending',
    this.queryMessage = '',
    this.createdAt = '',
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isQueryRaised => status == 'query_raised';

  factory BookingEntity.fromMap(Map<String, dynamic> map) {
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
    notes,
    status,
    queryMessage,
    createdAt,
  ];
}