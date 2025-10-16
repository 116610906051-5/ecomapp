import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/cloudinary_service.dart';
import '../providers/auth_provider.dart';

class LiveChatPage extends StatefulWidget {
  final String? chatRoomId;

  LiveChatPage({this.chatRoomId});

  @override
  _LiveChatPageState createState() => _LiveChatPageState();
}

class _LiveChatPageState extends State<LiveChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _currentChatRoomId;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get chatRoomId from arguments if not provided in constructor
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['chatRoomId'] != null) {
      _currentChatRoomId = args['chatRoomId'];
    } else {
      _currentChatRoomId = widget.chatRoomId;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_currentChatRoomId != null) {
      ChatService.leaveChatRoom(_currentChatRoomId!, false);
    }
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final firebaseUser = authProvider.user;

    if (user == null && firebaseUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (_currentChatRoomId == null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final customerId = user?.id ?? firebaseUser?.uid ?? '';
        final customerName = user?.displayName ?? user?.name ?? firebaseUser?.displayName ?? 'ลูกค้า';
        final customerEmail = user?.email ?? firebaseUser?.email ?? '';

        _currentChatRoomId = await ChatService.createOrJoinChatRoom(
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
        );

        await ChatService.joinChatRoom(_currentChatRoomId!, false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      await ChatService.joinChatRoom(_currentChatRoomId!, false);
    }

    // Mark messages as read
    if (_currentChatRoomId != null) {
      await ChatService.markMessagesAsRead(_currentChatRoomId!, false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentChatRoomId == null) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final firebaseUser = authProvider.user;

    final senderId = user?.id ?? firebaseUser?.uid ?? '';
    final senderName = user?.displayName ?? user?.name ?? firebaseUser?.displayName ?? 'ลูกค้า';
    final message = _messageController.text.trim();

    _messageController.clear();

    try {
      await ChatService.sendMessage(
        chatRoomId: _currentChatRoomId!,
        senderId: senderId,
        senderName: senderName,
        senderRole: 'customer',
        message: message,
      );

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถส่งข้อความได้: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_currentChatRoomId == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Upload image to Cloudinary
      final imageUrl = await _uploadImageToCloudinary(image);

      // Send message with image
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      final firebaseUser = authProvider.user;

      final senderId = user?.id ?? firebaseUser?.uid ?? '';
      final senderName = user?.displayName ?? user?.name ?? firebaseUser?.displayName ?? 'ลูกค้า';

      await ChatService.sendMessage(
        chatRoomId: _currentChatRoomId!,
        senderId: senderId,
        senderName: senderName,
        senderRole: 'customer',
        message: 'ส่งรูปภาพ',
        type: ChatMessageType.image,
        imageUrl: imageUrl,
      );

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถส่งรูปภาพได้: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<String> _uploadImageToCloudinary(XFile image) async {
    try {
      final String fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}';
      final File file = File(image.path);
      
      print('🔄 กำลังอัพโหลดรูปภาพแชทไปยัง Cloudinary...');
      
      final String? downloadUrl = await CloudinaryService.uploadChatImage(
        file, 
        fileName: fileName
      );
      
      if (downloadUrl == null) {
        throw Exception('ไม่สามารถอัพโหลดรูปภาพได้');
      }
      
      print('✅ อัพโหลดรูปภาพแชทสำเร็จ: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการอัพโหลดรูปภาพแชท: $e');
      throw Exception('ไม่สามารถอัพโหลดรูปภาพได้: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Color(0xFF6366F1),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'แชทสนับสนุน',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showChatInfo,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'กำลังเชื่อมต่อ...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Messages Area
                Expanded(
                  child: _currentChatRoomId != null
                      ? StreamBuilder<List<ChatMessage>>(
                          stream: ChatService.getChatMessages(_currentChatRoomId!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'เกิดข้อผิดพลาด',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.red[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final messages = snapshot.data ?? [];

                            if (messages.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'เริ่มสนทนาได้เลย',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'ทีมงานจะตอบกลับโดยเร็วที่สุด',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Auto scroll to bottom when new message arrives
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToBottom();
                            });

                            return ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                return _buildMessageBubble(messages[index]);
                              },
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            'ไม่สามารถเชื่อมต่อได้',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                ),

                // Input Area
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Image button
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isUploadingImage ? null : _pickAndSendImage,
                          icon: _isUploadingImage
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                  ),
                                )
                              : Icon(
                                  Icons.image,
                                  color: Color(0xFF6366F1),
                                  size: 20,
                                ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            controller: _messageController,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: 'พิมพ์ข้อความ...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isFromMe = message.senderRole == 'customer';
    final isSystem = message.senderRole == 'system';

    if (isSystem) {
      return _buildSystemMessage(message);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFromMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF6366F1).withOpacity(0.1),
              child: Icon(
                Icons.support_agent,
                size: 16,
                color: Color(0xFF6366F1),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isFromMe)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4, left: 12),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isFromMe ? Color(0xFF6366F1) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(isFromMe ? 18 : 4),
                      bottomRight: Radius.circular(isFromMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(message, isFromMe),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 4, left: 12, right: 12),
                  child: Text(
                    message.timeFormat,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isFromMe) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF10B981).withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 16,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message, bool isFromMe) {
    switch (message.type) {
      case ChatMessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 200,
                    maxHeight: 200,
                  ),
                  child: Image.network(
                    message.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFromMe ? Colors.white : Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'ไม่สามารถโหลดรูปภาพได้',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (message.message.isNotEmpty && message.message != 'ส่งรูปภาพ')
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  message.message,
                  style: TextStyle(
                    fontSize: 16,
                    color: isFromMe ? Colors.white : Color(0xFF1E293B),
                    height: 1.4,
                  ),
                ),
              ),
          ],
        );
      
      case ChatMessageType.text:
      default:
        return Text(
          message.message,
          style: TextStyle(
            fontSize: 16,
            color: isFromMe ? Colors.white : Color(0xFF1E293B),
            height: 1.4,
          ),
        );
    }
  }

  Widget _buildSystemMessage(ChatMessage message) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xFFF59E0B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFFF59E0B).withOpacity(0.3)),
          ),
          child: Text(
            message.message,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFF59E0B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _showChatInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF6366F1)),
                SizedBox(width: 12),
                Text(
                  'ข้อมูลการแชท',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoRow(Icons.access_time, 'เวลาทำการ', 'จันทร์-ศุกร์ 9:00-18:00'),
            _buildInfoRow(Icons.schedule, 'เวลาตอบกลับ', 'ภายใน 5-10 นาทีในเวลาทำการ'),
            _buildInfoRow(Icons.support_agent, 'ทีมสนับสนุน', 'พร้อมช่วยเหลือคุณ 24/7'),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'เข้าใจแล้ว',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Color(0xFF6366F1)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
