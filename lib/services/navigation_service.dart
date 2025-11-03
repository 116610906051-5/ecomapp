import 'package:flutter/material.dart';

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static Future<void> navigateToChat(String chatRoomId) async {
    print('🧭 Navigating to chat room: $chatRoomId');
    
    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Clear notification badge when navigating to chat
        // TODO: Implement markChatAsRead in AdvancedNotificationService
        // await AdvancedNotificationService().markChatAsRead(chatRoomId);
        
        // Navigate to live chat page with the specific chat room ID
        await Navigator.of(context).pushNamed(
          '/live-chat',
          arguments: {'chatRoomId': chatRoomId},
        );
      } else {
        print('❌ NavigatorKey context is null');
      }
    } catch (e) {
      print('❌ Error navigating to chat: $e');
    }
  }
  
  static void goBack() {
    final context = navigatorKey.currentContext;
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
  
  static Future<void> navigateToHome() async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }
}
