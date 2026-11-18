import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/chat_rooms_model.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Future<ChatRoomsModel> fetchMyRooms();
  Future<List<MessageModel>> fetchMessageHistory(String roomId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final DioClient _dioClient;

  const ChatRemoteDataSourceImpl(this._dioClient);

  @override
  Future<ChatRoomsModel> fetchMyRooms() async {
    final response = await _dioClient.dio.get(ApiEndpoints.myRooms);
    return ChatRoomsModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<MessageModel>> fetchMessageHistory(String roomId) async {
    final response =
    await _dioClient.dio.get(ApiEndpoints.messageHistory(roomId));
    final list = response.data as List<dynamic>;
    return list
        .map((item) => MessageModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}