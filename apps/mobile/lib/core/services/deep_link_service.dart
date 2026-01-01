import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

/// Service to handle deep links for the app
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Global navigator key for navigation from anywhere
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Stream controller for invite codes
  final _inviteCodeController = StreamController<String>.broadcast();
  Stream<String> get inviteCodeStream => _inviteCodeController.stream;

  /// Initialize the deep link service
  Future<void> init() async {
    // Handle link that launched the app (cold start)
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }

    // Handle links when app is already running (warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  /// Handle incoming deep link
  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link received: $uri');

    // Handle nyevibe://join/{code} format
    if (uri.scheme == 'nyevibe' && uri.host == 'join') {
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final code = pathSegments.first;
        debugPrint('Invite code from deep link: $code');
        _inviteCodeController.add(code);
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
    _inviteCodeController.close();
  }
}

/// Global instance
final deepLinkService = DeepLinkService();
