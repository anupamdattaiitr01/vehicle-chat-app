import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';

// Shared secret key for AES encryption (must match the backend ENCRYPTION_KEY)
const String encryptionKey = 'fleet_payload_secret_2026';

// Helper to encrypt JSON payloads in OpenSSL/CryptoJS-compatible AES format
String _encryptPayload(String plainText, String passphrase) {
  final salt = encrypt.IV.fromSecureRandom(8).bytes;
  final passBytes = utf8.encode(passphrase);

  // OpenSSL EVP_BytesToKey derivation (matches CryptoJS.AES.encrypt)
  final d1 = crypto.md5.convert([...passBytes, ...salt]).bytes;
  final d2 = crypto.md5.convert([...d1, ...passBytes, ...salt]).bytes;
  final d3 = crypto.md5.convert([...d2, ...passBytes, ...salt]).bytes;

  final key = encrypt.Key(Uint8List.fromList([...d1, ...d2]));
  final iv = encrypt.IV(Uint8List.fromList(d3));

  final encrypter = encrypt.Encrypter(
    encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
  );
  final encrypted = encrypter.encrypt(plainText, iv: iv);

  final saltedPrefix = utf8.encode('Salted__');
  final combined = Uint8List.fromList([
    ...saltedPrefix,
    ...salt,
    ...encrypted.bytes,
  ]);

  return base64.encode(combined);
}

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
// Login & Driver Registration Screen Interface
// ---------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _isLoadingManagers = false;
  String _errorMessage = '';
  String _successMessage = '';

  List<dynamic> _managers = [];
  String? _selectedManagerId;

  @override
  void initState() {
    super.initState();
    _fetchManagers();
  }

  // Fetch registered managers so the driver can pick exactly one manager
  Future<void> _fetchManagers() async {
    setState(() {
      _isLoadingManagers = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5001/api/rooms/managers'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _managers = data;
            if (_managers.isNotEmpty &&
                !_managers.any((m) => m['_id'] == _selectedManagerId)) {
              _selectedManagerId = _managers.first['_id'] as String;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load managers: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingManagers = false;
        });
      }
    }
  }

  Future<void> _submitAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      if (_isRegisterMode) {
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();
        final password = _passwordController.text.trim();

        if (name.isEmpty || phone.isEmpty || password.isEmpty) {
          setState(() {
            _errorMessage = 'Please fill in all fields.';
            _isLoading = false;
          });
          return;
        }

        if (_selectedManagerId == null || _selectedManagerId!.isEmpty) {
          setState(() {
            _errorMessage = 'Please select your assigned manager.';
            _isLoading = false;
          });
          return;
        }

        // 1. Encrypt Driver registration payload
        final rawPayload = json.encode({
          'name': name,
          'phone': phone,
          'password': password,
          'role': 'driver',
          'managerId': _selectedManagerId,
        });
        final encryptedPayload = _encryptPayload(rawPayload, encryptionKey);

        // 2. Call register endpoint
        final response = await http.post(
          Uri.parse('http://10.0.2.2:5001/api/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'data': encryptedPayload}),
        );

        final data = json.decode(response.body);

        if (response.statusCode == 201) {
          if (!mounted) return;
          setState(() {
            _successMessage = 'Driver registered! Please log in.';
            _passwordController.clear();
            _isRegisterMode = false; // Keep phone pre-filled for easy login
          });
        } else {
          setState(() {
            _errorMessage = data['error'] ?? 'Registration failed';
          });
        }
      } else {
        // 1. Build and encrypt login payload
        final rawPayload = json.encode({
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
        });
        final encryptedPayload = _encryptPayload(rawPayload, encryptionKey);

        // 2. Call login endpoint
        final response = await http.post(
          Uri.parse('http://10.0.2.2:5001/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'data': encryptedPayload}),
        );

        final data = json.decode(response.body);

        if (response.statusCode == 200) {
          if (data['user']['role'] != 'driver') {
            setState(() {
              _errorMessage = 'Access denied: This app is for Drivers only.';
            });
            return;
          }

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
    _nameController.dispose();
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
                Text(
                  _isRegisterMode ? 'Driver Registration' : 'Driver Login',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 20),

                if (_errorMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (_successMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _successMessage,
                      style: const TextStyle(color: Colors.green, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (_isRegisterMode) ...[
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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

                if (_isRegisterMode) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(_selectedManagerId),
                          initialValue: _selectedManagerId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Your Manager',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.supervisor_account),
                          ),
                          items: _managers.map((manager) {
                            return DropdownMenuItem<String>(
                              value: manager['_id'] as String,
                              child: Text(
                                '${manager['name']} (${manager['phone']})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedManagerId = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Refresh Managers',
                        onPressed: _isLoadingManagers ? null : _fetchManagers,
                        icon: _isLoadingManagers
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Role: Driver',
                      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : Text(
                      _isRegisterMode ? 'Register as Driver' : 'Login',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegisterMode = !_isRegisterMode;
                      _errorMessage = '';
                      _successMessage = '';
                    });
                    if (_isRegisterMode) {
                      _fetchManagers();
                    }
                  },
                  child: Text(
                    _isRegisterMode
                        ? 'Already registered? Login here'
                        : 'New Driver? Register here',
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
  final List<dynamic> _messages = [];

  // Dynamic room IDs fetched from /api/rooms/my-rooms
  String? _communityRoomId;
  String? _personalRoomId;
  String _managerName = 'Manager';
  bool _isLoadingRooms = true;

  int _selectedIndex = 0;
  String? _activeRoomId;

  bool _isManagerTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _connectToSocket();
    _fetchMyRooms();
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

  // Fetch Community Hub room and the driver's dedicated private room with their assigned manager
  Future<void> _fetchMyRooms() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5001/api/rooms/my-rooms'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _communityRoomId = data['communityRoomId'];
            if (data['manager'] != null) {
              _personalRoomId = data['manager']['roomId'];
              _managerName = data['manager']['managerName'] ?? 'Manager';
            }
            _activeRoomId = _selectedIndex == 0 ? _communityRoomId : _personalRoomId;
            _isLoadingRooms = false;
          });

          if (_activeRoomId != null) {
            _fetchHistory();
            if (socket.connected) {
              socket.emit('join_room', {
                'roomId': _activeRoomId,
                'userId': widget.driverId,
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch driver rooms: $e');
      if (mounted) {
        setState(() {
          _isLoadingRooms = false;
        });
      }
    }
  }

  void _onTabTapped(int index) {
    if (_selectedIndex == index) return;

    final nextRoomId = index == 0 ? _communityRoomId : _personalRoomId;

    setState(() {
      _selectedIndex = index;
      _activeRoomId = nextRoomId;
      _messages.clear();
      _isManagerTyping = false;
    });

    if (_activeRoomId != null) {
      _fetchHistory();
      socket.emit('join_room', {
        'roomId': _activeRoomId,
        'userId': widget.driverId,
      });
    }
  }

  Future<void> _fetchHistory() async {
    if (_activeRoomId == null) return;

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
          .setAuth({'token': widget.token})
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      if (_activeRoomId != null) {
        socket.emit('join_room', {
          'roomId': _activeRoomId,
          'userId': widget.driverId,
        });
      }
    });

    socket.on('receive_message', (data) {
      if (mounted) {
        final incoming = Map<String, dynamic>.from(data);
        if (incoming['roomId'] == null || incoming['roomId'] == _activeRoomId) {
          setState(() {
            _messages.add(incoming);
          });
          _scrollToBottom();
        }
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
    if (text.isEmpty || _activeRoomId == null) return;

    socket.emit('send_message', {
      'roomId': _activeRoomId,
      'senderId': widget.driverId,
      'content': text,
    });

    _messageController.clear();
    socket.emit('stop_typing', {'roomId': _activeRoomId});
  }

  void _onTyping(String value) {
    if (_activeRoomId == null) return;

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
        : 'Manager: $_managerName';

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
      body: _isLoadingRooms
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$_managerName is typing...',
                  style: const TextStyle(
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