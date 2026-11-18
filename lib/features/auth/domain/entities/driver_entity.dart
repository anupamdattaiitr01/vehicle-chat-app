import 'package:equatable/equatable.dart';

class DriverEntity extends Equatable {
  final String id;
  final String name;
  final String token;

  const DriverEntity({
    required this.id,
    required this.name,
    required this.token,
  });

  @override
  List<Object?> get props => [id, name, token];
}