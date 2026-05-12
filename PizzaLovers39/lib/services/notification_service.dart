// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:eventsource/eventsource.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:http/http.dart' as http;
// import 'api_config.dart';
//
// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();
//
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
//   //EventSource? _eventSource;
//   StreamSubscription? _sseSubscription;
//
//   // Callback for in-app notification display
//   Function(String title, String message)? onNotificationReceived;
//
//   Future<void> init() async {
//     // 1. Initialize Local Notifications
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosInit = DarwinInitializationSettings();
//     await _localNotifications.initialize(
//       const InitializationSettings(android: androidInit, iOS: iosInit),
//     );
//
//     // 2. Handle background messages
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//     // 3. Handle foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       if (message.notification != null) {
//         _showLocalNotification(
//           message.notification!.title ?? 'Pizza Lovers 39',
//           message.notification!.body ?? '',
//         );
//       }
//     });
//   }
//
//   Future<Map<String, bool>> getSettings(String token) async {
//     final response = await http.get(
//       Uri.parse(ApiConfig.notificationSettings),
//       headers: ApiConfig.headers(token),
//     );
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return {
//         'pushNotifications': data['pushNotifications'] ?? false,
//         'orderUpdates': data['orderUpdates'] ?? false,
//       };
//     }
//     return {'pushNotifications': false, 'orderUpdates': false};
//   }
//
//   Future<void> updateSettings(String token, bool push, bool order) async {
//     await http.patch(
//       Uri.parse(ApiConfig.notificationSettings),
//       headers: ApiConfig.headers(token),
//       body: jsonEncode({
//         'pushNotifications': push,
//         'orderUpdates': order,
//       }),
//     );
//
//     if (push) {
//       await registerPushToken(token);
//     }
//   }
//
//   Future<void> registerPushToken(String authToken) async {
//     NotificationSettings settings = await _fcm.requestPermission();
//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       String? fcmToken = await _fcm.getToken();
//       if (fcmToken != null) {
//         await http.post(
//           Uri.parse(ApiConfig.pushToken),
//           headers: ApiConfig.headers(authToken),
//           body: jsonEncode({
//             'token': fcmToken,
//             'platform': Platform.isAndroid ? 'android' : 'ios',
//           }),
//         );
//       }
//     }
//   }
//
//   void startSSEStream(String authToken, bool pushEnabled, bool orderEnabled) async {
//     stopSSEStream();
//
//     if (!pushEnabled && !orderEnabled) return;
//
//     try {
//       final url = "${ApiConfig.notificationStream}?token=$authToken";
//       // _eventSource = await EventSource.connect(url);
//
//       _sseSubscription = _eventSource!.listen((Event event) {
//         if (event.event == 'notification' || event.event == 'order:update') {
//           if (event.data != null) {
//             final data = jsonDecode(event.data!);
//             final title = data['title'] ?? 'Pizza Lovers 39';
//             final message = data['message'] ?? '';
//
//             if (onNotificationReceived != null) {
//               onNotificationReceived!(title, message);
//             }
//             _showLocalNotification(title, message);
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("SSE Stream Error: $e");
//     }
//   }
//
//   void stopSSEStream() {
//     _sseSubscription?.cancel();
//     _eventSource = null;
//   }
//
//   Future<void> _showLocalNotification(String title, String message) async {
//     const androidDetails = AndroidNotificationDetails(
//       'pizza_orders', 'Pizza Orders',
//       importance: Importance.max, priority: Priority.high,
//     );
//     const notificationDetails = NotificationDetails(android: androidDetails);
//     await _localNotifications.show(
//       DateTime.now().millisecond,
//       title,
//       message,
//       notificationDetails,
//     );
//   }
// }
//
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // Handle closed-app notifications if needed
//   debugPrint("Handling background message: ${message.messageId}");
// }


import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class NotificationService {
  static final NotificationService _instance =
  NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  StreamSubscription<SSEModel>? _sseSubscription;

  // Callback for in-app notifications
  Function(String title, String message)? onNotificationReceived;

  Future<void> init() async {
    // Local notification initialization
    const androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(settings);

    // Background messages
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          message.notification?.title ?? 'Pizza Lovers 39',
          message.notification?.body ?? '',
        );
      }
    });
  }

  Future<Map<String, bool>> getSettings(String token) async {
    final response = await http.get(
      Uri.parse(ApiConfig.notificationSettings),
      headers: ApiConfig.headers(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return {
        'pushNotifications': data['pushNotifications'] ?? false,
        'orderUpdates': data['orderUpdates'] ?? false,
      };
    }

    return {
      'pushNotifications': false,
      'orderUpdates': false,
    };
  }

  Future<void> updateSettings(
      String token,
      bool push,
      bool order,
      ) async {
    await http.patch(
      Uri.parse(ApiConfig.notificationSettings),
      headers: ApiConfig.headers(token),
      body: jsonEncode({
        'pushNotifications': push,
        'orderUpdates': order,
      }),
    );

    if (push) {
      await registerPushToken(token);
    }
  }

  Future<void> registerPushToken(String authToken) async {
    NotificationSettings settings =
    await _fcm.requestPermission();

    if (settings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      String? fcmToken = await _fcm.getToken();

      if (fcmToken != null) {
        await http.post(
          Uri.parse(ApiConfig.pushToken),
          headers: ApiConfig.headers(authToken),
          body: jsonEncode({
            'token': fcmToken,
            'platform':
            Platform.isAndroid ? 'android' : 'ios',
          }),
        );
      }
    }
  }

  void startSSEStream(
      String authToken,
      bool pushEnabled,
      bool orderEnabled,
      ) {
    stopSSEStream();

    if (!pushEnabled && !orderEnabled) return;

    try {
      final url =
          "${ApiConfig.notificationStream}?token=$authToken";

      _sseSubscription = SSEClient.subscribeToSSE(
        method: SSERequestType.GET,
        url: url, header: {},
      ).listen((event) {
        try {
          if (event.data != null) {
            final data = jsonDecode(event.data!);

            final title =
                data['title'] ?? 'Pizza Lovers 39';

            final message =
                data['message'] ?? '';

            if (onNotificationReceived != null) {
              onNotificationReceived!(title, message);
            }

            _showLocalNotification(title, message);
          }
        } catch (e) {
          debugPrint("Notification Parse Error: $e");
        }
      });
    } catch (e) {
      debugPrint("SSE Stream Error: $e");
    }
  }

  void stopSSEStream() {
    _sseSubscription?.cancel();
  }

  Future<void> _showLocalNotification(
      String title,
      String message,
      ) async {
    const androidDetails = AndroidNotificationDetails(
      'pizza_orders',
      'Pizza Orders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      message,
      notificationDetails,
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  debugPrint(
    "Handling background message: ${message.messageId}",
  );
}