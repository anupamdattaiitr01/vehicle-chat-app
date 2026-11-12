import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const VehicleChatApp());
}

class VehicleChatApp extends StatelessWidget {
  const VehicleChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fleet Driver Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ---------------------------------------------------------
// Login Screen Interface
// ---------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5001/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DriverChatScreen(
              driverId: data['user']['_id'],
              driverName: data['user']['name'],
              token: data['token'],
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Is the backend running?';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_car, size: 64, color: Color(0xFF2C3E50)),
                const SizedBox(height: 16),
                const Text(
                  'Driver Login',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 24),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  ),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Chat Screen Interface
// ---------------------------------------------------------
class DriverChatScreen extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String token;

  const DriverChatScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.token,
  });

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen> {
  late io.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List _messages = [];

  static const String communityRoomId = '651f8a700000000000000001';
  static const String personalRoomId = '651f8a700000000000000002';

  int _selectedIndex = 0;
  late String _activeRoomId;

  bool _isManagerTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _activeRoomId = communityRoomId;
    _fetchHistory();
    _connectToSocket();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTabTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
      _activeRoomId = index == 0 ? communityRoomId : personalRoomId;
      _messages.clear();
      _isManagerTyping = false;
    });

    _fetchHistory();

    socket.emit('join_room', {
      'roomId': _activeRoomId,
      'userId': widget.driverId,
    });
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5001/api/messages/$_activeRoomId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(data);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch message history: $e');
    }
  }

  void _connectToSocket() {
    socket = io.io(
      'http://10.0.2.2:5001',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
      // ADDED: Pass the JWT token during the socket connection handshake
          .setAuth({'token': widget.token})
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      socket.emit('join_room', {
        'roomId': _activeRoomId,
        'userId': widget.driverId,
      });
    });

    socket.on('receive_message', (data) {
      if (mounted) {
        setState(() {
          _messages.add(Map<String, dynamic>.from(data));
        });
        _scrollToBottom();
      }
    });

    socket.on('display_typing', (data) {
      if (mounted) {
        setState(() {
          _isManagerTyping = data['isTyping'] ?? false;
        });
        if (data['isTyping'] == true) _scrollToBottom();
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    socket.emit('send_message', {
      'roomId': _activeRoomId,
      'senderId': widget.driverId,
      'content': text,
    });

    _messageController.clear();
    socket.emit('stop_typing', {'roomId': _activeRoomId});
  }

  void _onTyping(String value) {
    socket.emit('typing', {
      'roomId': _activeRoomId,
      'userName': widget.driverName,
    });

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      socket.emit('stop_typing', {'roomId': _activeRoomId});
    });
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[date.month - 1];

      int hour = date.hour;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      final minute = date.minute.toString().padLeft(2, '0');

      return '$month ${date.day}, $hour:$minute $ampm';
    } catch (e) {
      return '';
    }
  }

  void _logout() {
    socket.disconnect();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitle = _selectedIndex == 0
        ? 'Community Hub'
        : 'Manager Chat (Personal)';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['senderId'] == widget.driverId;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 4, top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green[600] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg['content'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          _formatDateTime(msg['createdAt']),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_isManagerTyping)
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Manager is typing...',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _onTyping,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.green),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Personal Chat',
          ),
        ],
      ),
    );
  }
}