import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../screens/buyer/store_profile_page.dart';

/// Root navigator for deep links and global navigation.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Queued when a link arrives before the navigator is ready.
String? pendingStoreSellerId;

/// Shareable in-app link: `umart://store/{sellerId}`
String buildStoreShareLink(String sellerId) => 'umart://store/${sellerId.trim()}';

/// Parses `umart://store/{sellerId}`.
String? parseStoreSellerIdFromUri(Uri uri) {
  if (uri.scheme.toLowerCase() != 'umart') return null;
  if (uri.host.toLowerCase() != 'store') return null;

  if (uri.pathSegments.isNotEmpty) {
    final id = uri.pathSegments.first.trim();
    if (id.isNotEmpty) return id;
  }

  final path = uri.path.trim();
  if (path.length > 1) {
    final id = path.replaceFirst('/', '').trim();
    if (id.isNotEmpty) return id;
  }

  return null;
}

void openStoreProfileFromDeepLink(String sellerId) {
  final trimmed = sellerId.trim();
  if (trimmed.isEmpty) return;

  final nav = rootNavigatorKey.currentState;
  if (nav == null) {
    pendingStoreSellerId = trimmed;
    return;
  }

  nav.push(
    MaterialPageRoute(
      builder: (_) => StoreProfilePage(sellerId: trimmed),
    ),
  );
}

void flushPendingStoreDeepLink() {
  final id = pendingStoreSellerId;
  if (id == null || id.isEmpty) return;
  pendingStoreSellerId = null;
  openStoreProfileFromDeepLink(id);
}

/// Listens for `umart://store/...` while the user is inside the app shell.
class StoreDeepLinkListener extends StatefulWidget {
  final Widget child;

  const StoreDeepLinkListener({super.key, required this.child});

  @override
  State<StoreDeepLinkListener> createState() => _StoreDeepLinkListenerState();
}

class _StoreDeepLinkListenerState extends State<StoreDeepLinkListener> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    if (kIsWeb) return;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (_) {}

    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {},
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => flushPendingStoreDeepLink());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => flushPendingStoreDeepLink());
  }

  void _handleUri(Uri uri) {
    final sellerId = parseStoreSellerIdFromUri(uri);
    if (sellerId != null) {
      openStoreProfileFromDeepLink(sellerId);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
