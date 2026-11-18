import '../../domain/entities/manager_entity.dart';

class ManagerModel extends ManagerEntity {
  const ManagerModel({
    required super.id,
    required super.name,
    required super.phone,
  });

  factory ManagerModel.fromJson(Map<String, dynamic> json) {
    return ManagerModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Manager',
      phone: json['phone']?.toString() ?? '',
    );
  }
}