import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import '../models/chat.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        
        if (user == null) return child;

        return StreamBuilder<List<ChatRoom>>(
          stream: ChatService.getCustomerChatRooms(user.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return child;

            final chatRooms = snapshot.data!;
            final unreadCount = chatRooms.fold<int>(
              0,
              (sum, room) => sum + room.unreadByCustomer,
            );
            
            // Debug: Print unread count and room details
            print('🔔 NotificationBadge: Total unread count = $unreadCount');
            for (var room in chatRooms) {
              print('🔔 Room ${room.id}: unreadByCustomer = ${room.unreadByCustomer}');
            }

            return Stack(
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: child,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class AdminNotificationBadge extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AdminNotificationBadge({
    Key? key,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatRoom>>(
      stream: ChatService.getAllChatRooms(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return child;

        final chatRooms = snapshot.data!;
        final unreadCount = chatRooms.fold<int>(
          0,
          (sum, room) => sum + room.unreadByAdmin,
        );

        return Stack(
          children: [
            GestureDetector(
              onTap: onTap,
              child: child,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
