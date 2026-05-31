import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';

const String _kOrderChannelId = 'umart_orders';
const String _kOrderChannelName = 'Order alerts';
const String _kOrderChannelDesc = 'Push when you receive a new order';

bool get _supportsFirebasePush =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Must be a top-level function for background isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Do not show UI here; server should not target logged-out tokens after unregister.
}

class PushMessaging {
  PushMessaging._();
  static final PushMessaging instance = PushMessaging._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Last account that registered this device's FCM token (used on logout).
  String? _registeredUid;
  String? _registeredToken;

  Future<void> ensureInitialized() async {
    if (!_supportsFirebasePush || _initialized) return;
    _initialized = true;

    await _setupLocalNotifications();
    await _requestPermissions();

    // Only attach token if someone is already signed in (e.g. restored session).
    if (FirebaseAuth.instance.currentUser != null) {
      await _persistCurrentToken();
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (FirebaseAuth.instance.currentUser == null) return;
      await _saveTokenToFirestore(token);
    });

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  Future<void> onAuthUserChanged(User? user) async {
    if (!_supportsFirebasePush) return;
    if (user != null) {
      await _persistCurrentToken();
    } else {
      await unregisterCurrentDevice();
    }
  }

  /// Call before [FirebaseAuth.signOut] if you sign out outside [authStateChanges].
  Future<void> unregisterCurrentDevice() async {
    if (!_supportsFirebasePush) return;

    final uid = _registeredUid ?? FirebaseAuth.instance.currentUser?.uid;
    final token = _registeredToken ?? await FirebaseMessaging.instance.getToken();

    if (uid != null && token != null && token.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {'fcmTokens': FieldValue.arrayRemove([token])},
          SetOptions(merge: true),
        );
      } catch (e, st) {
        debugPrint('PushMessaging: failed to remove FCM token: $e\n$st');
      }
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e, st) {
      debugPrint('PushMessaging: deleteToken failed: $e\n$st');
    }

    try {
      await _local.cancelAll();
    } catch (_) {}

    _registeredUid = null;
    _registeredToken = null;
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _local.initialize(settings: initSettings);

    final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kOrderChannelId,
        _kOrderChannelName,
        description: _kOrderChannelDesc,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _persistCurrentToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'fcmTokens': FieldValue.arrayUnion([token])},
        SetOptions(merge: true),
      );
      _registeredUid = user.uid;
      _registeredToken = token;
    } catch (e, st) {
      debugPrint('PushMessaging: failed to save FCM token: $e\n$st');
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (FirebaseAuth.instance.currentUser == null) return;

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'UMart';
    final body = notification?.body ?? message.data['body'] ?? '';
    if (body.isEmpty && title == 'UMart') return;

    final androidDetails = AndroidNotificationDetails(
      _kOrderChannelId,
      _kOrderChannelName,
      channelDescription: _kOrderChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final id = message.hashCode & 0x7fffffff;
    await _local.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}
