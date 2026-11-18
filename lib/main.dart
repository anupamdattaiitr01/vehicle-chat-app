import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await initDependencies();
  await sl<NotificationService>().initialize();

  runApp(const VehicleChatApp());
}

class VehicleChatApp extends StatelessWidget {
  const VehicleChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fleet Driver Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}












































// import 'package:flutter/material.dart';
// import 'package:socket_io_client/socket_io_client.dart' as io;
// import 'package:http/http.dart' as http;
// import 'package:crypto/crypto.dart' as crypto;
// import 'package:encrypt/encrypt.dart' as encrypt;
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'dart:typed_data';
// import 'dart:convert';
// import 'dart:async';
//
// typedef NotificationData = Map<String, dynamic>;
//
// const String encryptionKey = String.fromEnvironment(
//   'ENCRYPTION_KEY',
//   defaultValue: 'fleet_payload_secret_2026',
// );
//
// const String apiBaseUrl = String.fromEnvironment(
//   'API_BASE_URL',
//   defaultValue: 'http://localhost:5001',
// );
//
// const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
//
// final FlutterLocalNotificationsPlugin _localNotifications =
// FlutterLocalNotificationsPlugin();
//
// final StreamController<NotificationData> _notificationTapStream =
// StreamController<NotificationData>.broadcast();
//
// const AndroidNotificationChannel _fleetNotificationChannel =
// AndroidNotificationChannel(
//   'fleet_chat_messages',
//   'Fleet Chat Messages',
//   description: 'Incoming messages from your manager and the fleet community',
//   importance: Importance.max,
//   playSound: true,
// );
//
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   debugPrint('Background FCM received: data=${message.data}');
//
//   if (message.notification == null && message.data.isNotEmpty) {
//     final plugin = FlutterLocalNotificationsPlugin();
//     const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     await plugin.initialize(
//       settings: const InitializationSettings(android: androidSettings),
//     );
//     await plugin.show(
//       id: DateTime.now().millisecondsSinceEpoch.remainder(1000000000),
//       title: message.data['title'] ??
//           message.data['senderName'] ??
//           'New Fleet Message',
//       body: message.data['body'] ??
//           message.data['content'] ??
//           'You have a new message',
//       notificationDetails: const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'fleet_chat_messages',
//           'Fleet Chat Messages',
//           channelDescription:
//           'Incoming messages from your manager and the fleet community',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//       ),
//       payload: json.encode(message.data),
//     );
//   }
// }
//
// String _encryptPayload(String plainText, String passphrase) {
//   final salt = encrypt.IV.fromSecureRandom(8).bytes;
//   final passBytes = utf8.encode(passphrase);
//
//   final d1 = crypto.md5.convert([...passBytes, ...salt]).bytes;
//   final d2 = crypto.md5.convert([...d1, ...passBytes, ...salt]).bytes;
//   final d3 = crypto.md5.convert([...d2, ...passBytes, ...salt]).bytes;
//
//   final key = encrypt.Key(Uint8List.fromList([...d1, ...d2]));
//   final iv = encrypt.IV(Uint8List.fromList(d3));
//
//   final encrypter = encrypt.Encrypter(
//     encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
//   );
//   final encrypted = encrypter.encrypt(plainText, iv: iv);
//
//   final saltedPrefix = utf8.encode('Salted__');
//   final combined = Uint8List.fromList([
//     ...saltedPrefix,
//     ...salt,
//     ...encrypted.bytes,
//   ]);
//
//   return base64.encode(combined);
// }
//
// int _tabIndexFromRoomType(String? roomType) {
//   final normalized = roomType?.toLowerCase().trim();
//   if (normalized == 'personal' ||
//       normalized == 'private' ||
//       normalized == 'direct') {
//     return 1;
//   }
//   return 0;
// }
//
// Future<void> _initLocalNotifications() async {
//   const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//   const iosSettings = DarwinInitializationSettings();
//   const initSettings = InitializationSettings(
//     android: androidSettings,
//     iOS: iosSettings,
//   );
//
//   await _localNotifications.initialize(
//     settings: initSettings,
//     onDidReceiveNotificationResponse: (NotificationResponse response) {
//       if (response.payload != null && response.payload!.isNotEmpty) {
//         try {
//           final decoded = json.decode(response.payload!);
//           if (decoded is NotificationData) {
//             _notificationTapStream.add(decoded);
//             return;
//           }
//         } catch (_) {}
//         _notificationTapStream.add({'roomType': response.payload!});
//       }
//     },
//   );
//
//   final androidPlugin =
//   _localNotifications.resolvePlatformSpecificImplementation<
//       AndroidFlutterLocalNotificationsPlugin>();
//   await androidPlugin?.requestNotificationsPermission();
//   await androidPlugin?.createNotificationChannel(_fleetNotificationChannel);
// }
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//   await FirebaseMessaging.instance.requestPermission(
//     alert: true,
//     badge: true,
//     sound: true,
//   );
//
//   await _initLocalNotifications();
//
//   runApp(const VehicleChatApp());
// }
//
// class VehicleChatApp extends StatelessWidget {
//   const VehicleChatApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Fleet Driver Chat',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//       ),
//       home: const AuthWrapper(),
//     );
//   }
// }
//
// class AuthWrapper extends StatefulWidget {
//   const AuthWrapper({super.key});
//
//   @override
//   State<AuthWrapper> createState() => _AuthWrapperState();
// }
//
// class _AuthWrapperState extends State<AuthWrapper> {
//   @override
//   void initState() {
//     super.initState();
//     _restoreSessionAndCheckNotification();
//   }
//
//   Future<void> _restoreSessionAndCheckNotification() async {
//     try {
//       final RemoteMessage? initialMessage =
//       await FirebaseMessaging.instance.getInitialMessage();
//       final String? initialRoomType = initialMessage?.data['roomType'];
//       final int initialTab = _tabIndexFromRoomType(initialRoomType);
//
//       final token = await _secureStorage.read(key: 'jwt_token');
//       final driverId = await _secureStorage.read(key: 'driver_id');
//       final driverName = await _secureStorage.read(key: 'driver_name');
//
//       if (!mounted) return;
//
//       if (token != null &&
//           token.isNotEmpty &&
//           driverId != null &&
//           driverName != null) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DriverChatScreen(
//               driverId: driverId,
//               driverName: driverName,
//               token: token,
//               initialTabIndex: initialTab,
//               initialRoomId: initialMessage?.data['roomId'],
//             ),
//           ),
//         );
//       } else {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => LoginScreen(
//               pendingTabIndex: initialMessage != null ? initialTab : 0,
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint('Session restore error: $e');
//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const LoginScreen()),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       backgroundColor: Color(0xFFECF0F1),
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.directions_car, size: 64, color: Color(0xFF2C3E50)),
//             SizedBox(height: 16),
//             CircularProgressIndicator(),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class LoginScreen extends StatefulWidget {
//   final int pendingTabIndex;
//
//   const LoginScreen({super.key, this.pendingTabIndex = 0});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//
//   bool _isRegisterMode = false;
//   bool _isLoading = false;
//   bool _isLoadingManagers = false;
//   String _errorMessage = '';
//   String _successMessage = '';
//
//   List<dynamic> _managers = [];
//   String? _selectedManagerId;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchManagers();
//   }
//
//   Future<void> _fetchManagers() async {
//     setState(() {
//       _isLoadingManagers = true;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('$apiBaseUrl/api/rooms/managers'),
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         if (mounted) {
//           setState(() {
//             _managers = data;
//             if (_managers.isNotEmpty &&
//                 !_managers.any((m) => m['_id'] == _selectedManagerId)) {
//               _selectedManagerId = _managers.first['_id'] as String;
//             }
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint('Failed to load managers: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoadingManagers = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _submitAuth() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//       _successMessage = '';
//     });
//
//     try {
//       if (_isRegisterMode) {
//         final name = _nameController.text.trim();
//         final phone = _phoneController.text.trim();
//         final password = _passwordController.text.trim();
//
//         if (name.isEmpty || phone.isEmpty || password.isEmpty) {
//           setState(() {
//             _errorMessage = 'Please fill in all fields.';
//             _isLoading = false;
//           });
//           return;
//         }
//
//         if (_selectedManagerId == null || _selectedManagerId!.isEmpty) {
//           setState(() {
//             _errorMessage = 'Please select your assigned manager.';
//             _isLoading = false;
//           });
//           return;
//         }
//
//         final rawPayload = json.encode({
//           'name': name,
//           'phone': phone,
//           'password': password,
//           'role': 'driver',
//           'managerId': _selectedManagerId,
//         });
//         final encryptedPayload = _encryptPayload(rawPayload, encryptionKey);
//
//         final response = await http.post(
//           Uri.parse('$apiBaseUrl/api/auth/register'),
//           headers: {'Content-Type': 'application/json'},
//           body: json.encode({'data': encryptedPayload}),
//         );
//
//         final data = json.decode(response.body);
//
//         if (response.statusCode == 201) {
//           if (!mounted) return;
//           setState(() {
//             _successMessage = 'Driver registered! Please log in.';
//             _passwordController.clear();
//             _isRegisterMode = false;
//           });
//         } else {
//           setState(() {
//             _errorMessage = data['error'] ?? 'Registration failed';
//           });
//         }
//       } else {
//         final rawPayload = json.encode({
//           'phone': _phoneController.text.trim(),
//           'password': _passwordController.text.trim(),
//         });
//         final encryptedPayload = _encryptPayload(rawPayload, encryptionKey);
//
//         final response = await http.post(
//           Uri.parse('$apiBaseUrl/api/auth/login'),
//           headers: {'Content-Type': 'application/json'},
//           body: json.encode({'data': encryptedPayload}),
//         );
//
//         final data = json.decode(response.body);
//
//         if (response.statusCode == 200) {
//           if (data['user']['role'] != 'driver') {
//             setState(() {
//               _errorMessage = 'Access denied: This app is for Drivers only.';
//             });
//             return;
//           }
//
//           final String token = data['token'];
//           final String driverId = data['user']['_id'];
//           final String driverName = data['user']['name'];
//
//           await _secureStorage.write(key: 'jwt_token', value: token);
//           await _secureStorage.write(key: 'driver_id', value: driverId);
//           await _secureStorage.write(key: 'driver_name', value: driverName);
//
//           if (!mounted) return;
//
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => DriverChatScreen(
//                 driverId: driverId,
//                 driverName: driverName,
//                 token: token,
//                 initialTabIndex: widget.pendingTabIndex,
//               ),
//             ),
//           );
//         } else {
//           setState(() {
//             _errorMessage = data['error'] ?? 'Login failed';
//           });
//         }
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Network error. Is the backend running?';
//       });
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _phoneController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFECF0F1),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Container(
//             padding: const EdgeInsets.all(24.0),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.1),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(Icons.directions_car, size: 64, color: Color(0xFF2C3E50)),
//                 const SizedBox(height: 16),
//                 Text(
//                   _isRegisterMode ? 'Driver Registration' : 'Driver Login',
//                   style: const TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF2C3E50),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//
//                 if (_errorMessage.isNotEmpty)
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(10),
//                     margin: const EdgeInsets.only(bottom: 16),
//                     decoration: BoxDecoration(
//                       color: Colors.red.shade50,
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       _errorMessage,
//                       style: const TextStyle(color: Colors.red, fontSize: 13),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//
//                 if (_successMessage.isNotEmpty)
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(10),
//                     margin: const EdgeInsets.only(bottom: 16),
//                     decoration: BoxDecoration(
//                       color: Colors.green.shade50,
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       _successMessage,
//                       style: const TextStyle(color: Colors.green, fontSize: 13),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//
//                 if (_isRegisterMode) ...[
//                   TextField(
//                     controller: _nameController,
//                     textCapitalization: TextCapitalization.words,
//                     decoration: const InputDecoration(
//                       labelText: 'Full Name',
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.person),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                 ],
//
//                 TextField(
//                   controller: _phoneController,
//                   keyboardType: TextInputType.phone,
//                   decoration: const InputDecoration(
//                     labelText: 'Phone Number',
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.phone),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//
//                 TextField(
//                   controller: _passwordController,
//                   obscureText: true,
//                   decoration: const InputDecoration(
//                     labelText: 'Password',
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.lock),
//                   ),
//                 ),
//
//                 if (_isRegisterMode) ...[
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: DropdownButtonFormField<String>(
//                           key: ValueKey(_selectedManagerId),
//                           initialValue: _selectedManagerId,
//                           isExpanded: true,
//                           decoration: const InputDecoration(
//                             labelText: 'Select Your Manager',
//                             border: OutlineInputBorder(),
//                             prefixIcon: Icon(Icons.supervisor_account),
//                           ),
//                           items: _managers.map((manager) {
//                             return DropdownMenuItem<String>(
//                               value: manager['_id'] as String,
//                               child: Text(
//                                 '${manager['name']} (${manager['phone']})',
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             );
//                           }).toList(),
//                           onChanged: (value) {
//                             setState(() {
//                               _selectedManagerId = value;
//                             });
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       IconButton(
//                         tooltip: 'Refresh Managers',
//                         onPressed: _isLoadingManagers ? null : _fetchManagers,
//                         icon: _isLoadingManagers
//                             ? const SizedBox(
//                           width: 18,
//                           height: 18,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                             : const Icon(Icons.refresh),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(6),
//                       border: Border.all(color: Colors.grey.shade300),
//                     ),
//                     child: const Text(
//                       'Role: Driver',
//                       style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
//                     ),
//                   ),
//                 ],
//
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 48,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _submitAuth,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
//                     )
//                         : Text(
//                       _isRegisterMode ? 'Register as Driver' : 'Login',
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextButton(
//                   onPressed: () {
//                     setState(() {
//                       _isRegisterMode = !_isRegisterMode;
//                       _errorMessage = '';
//                       _successMessage = '';
//                     });
//                     if (_isRegisterMode) {
//                       _fetchManagers();
//                     }
//                   },
//                   child: Text(
//                     _isRegisterMode
//                         ? 'Already registered? Login here'
//                         : 'New Driver? Register here',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class DriverChatScreen extends StatefulWidget {
//   final String driverId;
//   final String driverName;
//   final String token;
//   final int initialTabIndex;
//   final String? initialRoomId;
//
//   const DriverChatScreen({
//     super.key,
//     required this.driverId,
//     required this.driverName,
//     required this.token,
//     this.initialTabIndex = 0,
//     this.initialRoomId,
//   });
//
//   @override
//   State<DriverChatScreen> createState() => _DriverChatScreenState();
// }
//
// class _DriverChatScreenState extends State<DriverChatScreen>
//     with WidgetsBindingObserver {
//   late io.Socket socket;
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final List<dynamic> _messages = [];
//
//   String? _communityRoomId;
//   String? _personalRoomId;
//   String _managerName = 'Manager';
//   bool _isLoadingRooms = true;
//
//   bool _isConnected = false;
//
//   late int _selectedIndex;
//   String? _activeRoomId;
//
//   bool _isManagerTyping = false;
//   Timer? _typingTimer;
//
//   StreamSubscription<RemoteMessage>? _foregroundMsgSub;
//   StreamSubscription<RemoteMessage>? _openedAppMsgSub;
//   StreamSubscription<NotificationData>? _localNotifTapSub;
//   StreamSubscription<String>? _tokenRefreshSub;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _selectedIndex = widget.initialTabIndex;
//
//     _bindNotificationListeners();
//     _syncFcmToken();
//     _connectToSocket();
//     _fetchMyRooms();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused ||
//         state == AppLifecycleState.inactive) {
//       if (socket.connected && _activeRoomId != null) {
//         socket.emit('leave_room', {
//           'roomId': _activeRoomId,
//           'userId': widget.driverId,
//         });
//       }
//     } else if (state == AppLifecycleState.resumed) {
//       if (!socket.connected) {
//         socket.connect();
//       } else if (_activeRoomId != null) {
//         socket.emit('join_room', {
//           'roomId': _activeRoomId,
//           'userId': widget.driverId,
//         });
//         _fetchHistory();
//       }
//     }
//   }
//
//   int _resolveTargetTab(NotificationData data) {
//     final incomingRoomId = data['roomId']?.toString();
//     if (incomingRoomId != null && incomingRoomId.isNotEmpty) {
//       if (_personalRoomId != null && incomingRoomId == _personalRoomId) {
//         return 1;
//       }
//       if (_communityRoomId != null && incomingRoomId == _communityRoomId) {
//         return 0;
//       }
//     }
//     return _tabIndexFromRoomType(data['roomType']?.toString());
//   }
//
//   void _bindNotificationListeners() {
//     _openedAppMsgSub?.cancel();
//     _openedAppMsgSub =
//         FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//           debugPrint('Background notification tapped: ${message.data}');
//           _navigateToRoomTab(_resolveTargetTab(message.data));
//         });
//
//     _foregroundMsgSub?.cancel();
//     _foregroundMsgSub =
//         FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//           debugPrint('Foreground FCM arrived: ${message.data}');
//           final targetTab = _resolveTargetTab(message.data);
//
//           if (targetTab != _selectedIndex) {
//             final title = message.notification?.title ??
//                 message.data['title'] ??
//                 message.data['senderName'] ??
//                 'New Fleet Message';
//             final body = message.notification?.body ??
//                 message.data['body'] ??
//                 message.data['content'] ??
//                 '';
//
//             _localNotifications.show(
//               id: DateTime.now().millisecondsSinceEpoch.remainder(1000000000),
//               title: title,
//               body: body,
//               notificationDetails: NotificationDetails(
//                 android: AndroidNotificationDetails(
//                   _fleetNotificationChannel.id,
//                   _fleetNotificationChannel.name,
//                   channelDescription: _fleetNotificationChannel.description,
//                   importance: Importance.max,
//                   priority: Priority.high,
//                 ),
//               ),
//               payload: json.encode(message.data),
//             );
//           }
//         });
//
//     _localNotifTapSub?.cancel();
//     _localNotifTapSub = _notificationTapStream.stream.listen((data) {
//       _navigateToRoomTab(_resolveTargetTab(data));
//     });
//
//     _tokenRefreshSub?.cancel();
//     // ignore: deprecated_member_use
//     _tokenRefreshSub =
//         FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
//           debugPrint('FCM Refreshed Token: $newToken');
//           _sendFcmTokenToBackend(newToken);
//         });
//   }
//
//   Future<void> _syncFcmToken() async {
//     try {
//       // ignore: deprecated_member_use
//       final currentToken = await FirebaseMessaging.instance.getToken();
//       debugPrint('FCM Current Token: $currentToken');
//       if (currentToken != null && currentToken.isNotEmpty) {
//         await _sendFcmTokenToBackend(currentToken);
//       } else if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('FCM Warning: Device returned an empty push token.'),
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint('Error syncing FCM token: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('FCM Token Error: $e'),
//             duration: const Duration(seconds: 6),
//           ),
//         );
//       }
//     }
//   }
//
//   Future<void> _sendFcmTokenToBackend(String fcmToken) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$apiBaseUrl/api/auth/fcm-token'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${widget.token}',
//         },
//         body: json.encode({'fcmToken': fcmToken}),
//       );
//       debugPrint('FCM Token sync status: ${response.statusCode} ${response.body}');
//     } catch (e) {
//       debugPrint('Failed to sync FCM token to backend: $e');
//     }
//   }
//
//   void _navigateToRoomTab(int targetIndex) {
//     if (!mounted) return;
//     if (_selectedIndex == targetIndex) {
//       _fetchHistory();
//       return;
//     }
//     _onTabTapped(targetIndex);
//   }
//
//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
//
//   Future<void> _fetchMyRooms() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$apiBaseUrl/api/rooms/my-rooms'),
//         headers: {'Authorization': 'Bearer ${widget.token}'},
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (mounted) {
//           setState(() {
//             _communityRoomId = data['communityRoomId'];
//             if (data['manager'] != null) {
//               _personalRoomId = data['manager']['roomId'];
//               _managerName = data['manager']['managerName'] ?? 'Manager';
//             }
//             if (widget.initialRoomId != null &&
//                 widget.initialRoomId == _personalRoomId) {
//               _selectedIndex = 1;
//             }
//             _activeRoomId =
//             _selectedIndex == 0 ? _communityRoomId : _personalRoomId;
//             _isLoadingRooms = false;
//           });
//
//           if (_activeRoomId != null) {
//             _fetchHistory();
//             if (socket.connected) {
//               socket.emit('join_room', {
//                 'roomId': _activeRoomId,
//                 'userId': widget.driverId,
//               });
//             }
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Failed to fetch driver rooms: $e');
//       if (mounted) {
//         setState(() {
//           _isLoadingRooms = false;
//         });
//       }
//     }
//   }
//
//   void _onTabTapped(int index) {
//     if (_selectedIndex == index) return;
//
//     final previousRoomId = _activeRoomId;
//     final nextRoomId = index == 0 ? _communityRoomId : _personalRoomId;
//
//     if (socket.connected && previousRoomId != null) {
//       socket.emit('leave_room', {
//         'roomId': previousRoomId,
//         'userId': widget.driverId,
//       });
//     }
//
//     setState(() {
//       _selectedIndex = index;
//       _activeRoomId = nextRoomId;
//       _messages.clear();
//       _isManagerTyping = false;
//     });
//
//     if (_activeRoomId != null) {
//       _fetchHistory();
//       if (socket.connected) {
//         socket.emit('join_room', {
//           'roomId': _activeRoomId,
//           'userId': widget.driverId,
//         });
//       }
//     }
//   }
//
//   Future<void> _fetchHistory() async {
//     if (_activeRoomId == null) return;
//
//     try {
//       final response = await http.get(
//         Uri.parse('$apiBaseUrl/api/messages/$_activeRoomId'),
//         headers: {'Authorization': 'Bearer ${widget.token}'},
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         if (mounted) {
//           setState(() {
//             _messages.clear();
//             _messages.addAll(data);
//           });
//           _scrollToBottom();
//         }
//       }
//     } catch (e) {
//       debugPrint('Failed to fetch message history: $e');
//     }
//   }
//
//   void _connectToSocket() {
//     socket = io.io(
//       apiBaseUrl,
//       io.OptionBuilder()
//           .setTransports(['websocket'])
//           .disableAutoConnect()
//           .enableReconnection()
//           .setReconnectionAttempts(999999)
//           .setReconnectionDelay(1000)
//           .setReconnectionDelayMax(5000)
//           .setAuth({'token': widget.token})
//           .build(),
//     );
//
//     socket.connect();
//
//     socket.onConnect((_) {
//       if (mounted) {
//         setState(() {
//           _isConnected = true;
//         });
//       }
//
//       // Re-sync FCM token on every connect/reconnect so backend restarts never lose it
//       _syncFcmToken();
//
//       if (_activeRoomId == null) {
//         _fetchMyRooms();
//       } else {
//         socket.emit('join_room', {
//           'roomId': _activeRoomId,
//           'userId': widget.driverId,
//         });
//         _fetchHistory();
//       }
//     });
//
//     socket.onDisconnect((_) {
//       if (mounted) {
//         setState(() {
//           _isConnected = false;
//           _isManagerTyping = false;
//         });
//       }
//     });
//
//     socket.onConnectError((_) {
//       if (mounted) {
//         setState(() {
//           _isConnected = false;
//         });
//       }
//     });
//
//     socket.on('receive_message', (data) {
//       if (mounted) {
//         final incoming = NotificationData.from(data);
//         if (incoming['roomId'] == null || incoming['roomId'] == _activeRoomId) {
//           final incomingId = incoming['_id'];
//           final alreadyExists = incomingId != null &&
//               _messages.any((m) => m['_id'] == incomingId);
//
//           if (!alreadyExists) {
//             setState(() {
//               _messages.add(incoming);
//             });
//             _scrollToBottom();
//           }
//         }
//       }
//     });
//
//     socket.on('display_typing', (data) {
//       if (mounted) {
//         setState(() {
//           _isManagerTyping = data['isTyping'] ?? false;
//         });
//         if (data['isTyping'] == true) _scrollToBottom();
//       }
//     });
//   }
//
//   void _sendMessage() {
//     final text = _messageController.text.trim();
//     if (text.isEmpty || _activeRoomId == null) return;
//
//     if (!_isConnected || !socket.connected) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Offline — waiting for network to reconnect...'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//       return;
//     }
//
//     socket.emit('send_message', {
//       'roomId': _activeRoomId,
//       'senderId': widget.driverId,
//       'content': text,
//     });
//
//     _messageController.clear();
//     socket.emit('stop_typing', {'roomId': _activeRoomId});
//   }
//
//   void _onTyping(String value) {
//     if (_activeRoomId == null || !_isConnected) return;
//
//     socket.emit('typing', {
//       'roomId': _activeRoomId,
//       'userName': widget.driverName,
//     });
//
//     _typingTimer?.cancel();
//     _typingTimer = Timer(const Duration(milliseconds: 1500), () {
//       if (socket.connected) {
//         socket.emit('stop_typing', {'roomId': _activeRoomId});
//       }
//     });
//   }
//
//   String _formatDateTime(String? isoString) {
//     if (isoString == null) return '';
//     try {
//       final date = DateTime.parse(isoString).toLocal();
//       final months = [
//         'Jan',
//         'Feb',
//         'Mar',
//         'Apr',
//         'May',
//         'Jun',
//         'Jul',
//         'Aug',
//         'Sep',
//         'Oct',
//         'Nov',
//         'Dec'
//       ];
//       final month = months[date.month - 1];
//
//       int hour = date.hour;
//       final period = hour >= 12 ? 'PM' : 'AM';
//       if (hour > 12) hour -= 12;
//       if (hour == 0) hour = 12;
//
//       final minute = date.minute.toString().padLeft(2, '0');
//
//       return '$month ${date.day}, $hour:$minute $period';
//     } catch (e) {
//       return '';
//     }
//   }
//
//   Future<void> _logout() async {
//     try {
//       await http.delete(
//         Uri.parse('$apiBaseUrl/api/auth/fcm-token'),
//         headers: {'Authorization': 'Bearer ${widget.token}'},
//       );
//     } catch (e) {
//       debugPrint('Failed to clear FCM token on logout: $e');
//     }
//
//     await _secureStorage.deleteAll();
//
//     socket.disconnect();
//     if (!mounted) return;
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const LoginScreen()),
//     );
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _foregroundMsgSub?.cancel();
//     _openedAppMsgSub?.cancel();
//     _localNotifTapSub?.cancel();
//     _tokenRefreshSub?.cancel();
//     socket.disconnect();
//     socket.dispose();
//     _messageController.dispose();
//     _scrollController.dispose();
//     _typingTimer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final appBarTitle = _selectedIndex == 0
//         ? 'Community Hub'
//         : 'Manager: $_managerName';
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(appBarTitle),
//         backgroundColor: const Color(0xFF2C3E50),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: _logout,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           if (!_isConnected && !_isLoadingRooms)
//             Container(
//               width: double.infinity,
//               color: Colors.orange.shade800,
//               padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   SizedBox(
//                     width: 12,
//                     height: 12,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   Text(
//                     'Connection lost — Reconnecting...',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//           Expanded(
//             child: _isLoadingRooms
//                 ? const Center(child: CircularProgressIndicator())
//                 : ListView.builder(
//               controller: _scrollController,
//               padding: const EdgeInsets.all(16),
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 final msg = _messages[index];
//                 final isMe = msg['senderId'] == widget.driverId;
//
//                 return Align(
//                   alignment: isMe
//                       ? Alignment.centerRight
//                       : Alignment.centerLeft,
//                   child: Column(
//                     crossAxisAlignment: isMe
//                         ? CrossAxisAlignment.end
//                         : CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         margin: const EdgeInsets.only(bottom: 4, top: 8),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 14, vertical: 10),
//                         decoration: BoxDecoration(
//                           color: isMe
//                               ? Colors.green[600]
//                               : Colors.grey[300],
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: Text(
//                           msg['content'] ?? '',
//                           style: TextStyle(
//                             color: isMe ? Colors.white : Colors.black87,
//                             fontSize: 15,
//                           ),
//                         ),
//                       ),
//                       Padding(
//                         padding:
//                         const EdgeInsets.symmetric(horizontal: 4),
//                         child: Text(
//                           _formatDateTime(msg['createdAt']),
//                           style: const TextStyle(
//                             fontSize: 10,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//
//           if (_isManagerTyping)
//             Padding(
//               padding: const EdgeInsets.only(left: 16, bottom: 6),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   '$_managerName is typing...',
//                   style: const TextStyle(
//                     fontStyle: FontStyle.italic,
//                     color: Colors.grey,
//                     fontSize: 13,
//                   ),
//                 ),
//               ),
//             ),
//
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.05),
//                   blurRadius: 5,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: SafeArea(
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _messageController,
//                       onChanged: _onTyping,
//                       decoration: const InputDecoration(
//                         hintText: 'Type a message...',
//                         border: OutlineInputBorder(),
//                         contentPadding: EdgeInsets.symmetric(
//                             horizontal: 14, vertical: 10),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   IconButton(
//                     icon: Icon(
//                       Icons.send,
//                       color: _isConnected ? Colors.green : Colors.grey,
//                     ),
//                     onPressed: _sendMessage,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onTabTapped,
//         selectedItemColor: Colors.blue,
//         unselectedItemColor: Colors.grey,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.people),
//             label: 'Community Hub',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Personal Chat',
//           ),
//         ],
//       ),
//     );
//   }
// }