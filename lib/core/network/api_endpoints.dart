class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/api/auth/login';
  static const String fcmToken = '/api/auth/fcm-token';

  // Rooms & Messages
  static const String myRooms = '/api/rooms/my-rooms';
  static String messageHistory(String roomId) => '/api/messages/$roomId';
}