import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';

typedef SocketEventData = Map<String, dynamic>;

class SocketService {
  io.Socket? _socket;

  final StreamController<bool> _connectionController =
  StreamController<bool>.broadcast();
  final StreamController<SocketEventData> _messageController =
  StreamController<SocketEventData>.broadcast();
  final StreamController<SocketEventData> _typingController =
  StreamController<SocketEventData>.broadcast();

  bool _isConnected = false;

  bool get isConnected => _isConnected;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<SocketEventData> get messageStream => _messageController.stream;
  Stream<SocketEventData> get typingStream => _typingController.stream;

  void connect(String token) {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
    }

    _socket = io.io(
      AppConstants.apiBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onConnectError((_) {
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.on('receive_message', (data) {
      if (data is Map) {
        _messageController.add(SocketEventData.from(data));
      }
    });

    _socket!.on('display_typing', (data) {
      if (data is Map) {
        _typingController.add(SocketEventData.from(data));
      }
    });

    _socket!.connect();
  }

  void reconnectIfDisconnected() {
    if (_socket != null && !_socket!.connected) {
      _socket!.connect();
    }
  }

  void emit(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
    }
  }

  void disconnect() {
    _isConnected = false;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _connectionController.close();
    _messageController.close();
    _typingController.close();
  }
}