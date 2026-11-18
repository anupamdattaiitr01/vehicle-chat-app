import '../../domain/entities/driver_entity.dart';

class DriverModel extends DriverEntity {
  const DriverModel({
    required super.id,
    required super.name,
    required super.token,
  });

  factory DriverModel.fromLoginJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return DriverModel(
      id: user['_id']?.toString() ?? '',
      name: user['name']?.toString() ?? 'Driver',
      token: json['token']?.toString() ?? '',
    );
  }
}