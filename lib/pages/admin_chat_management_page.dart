import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';

class AdminChatManagementPage extends StatefulWidget {
  @override
  _AdminChatManagementPageState createState() => _AdminChatManagementPageState();
}

class _AdminChatManagementPageState extends State<AdminChatManagementPage> {
  String _selectedFilter = 'all'; // all, waiting, active, resolved, closed
  String _searchQuery = '';
  String _currentInput = ''; // Track current input for display
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _recentSearches = [];
  final ValueNotifier<bool> _suggestionsNotifier = ValueNotifier<bool>(false);
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    print('🔍 AdminChatManagementPage initialized'); // Debug
    
    // Hide suggestions when focus is lost
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        Future.delayed(Duration(milliseconds: 200), () {
          _suggestionsNotifier.value = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _suggestionsNotifier.dispose();
    super.dispose();
  }

  void _addToRecentSearches(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 5) {
          _recentSearches = _recentSearches.take(5).toList();
        }
      });
    }
  }

  void _performSearch(String value) {
    print('🔍 Performing search for: $value'); // Debug
    _addToRecentSearches(value);
    _suggestionsNotifier.value = false;
    setState(() {
      _searchQuery = value;
      _currentInput = value;
    });
    _searchFocusNode.unfocus();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Color(0xFF6366F1),
        elevation: 0,
        title: Text(
          'จัดการแชทลูกค้า',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: ChatService.getAllChatRooms(),
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
                    size: 64,
                    color: Colors.red[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final allChatRooms = snapshot.data ?? [];
          
          // Filter and search chat rooms
          final filteredRooms = _filterChatRooms(allChatRooms);
          final chatRooms = _searchChatRooms(filteredRooms);

          return Column(
            children: [
              // Search Bar
              _buildSearchBar(),
              
              // Filter Tabs
              _buildFilterTabs(allChatRooms),
              
              // Stats Header
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      '${allChatRooms.length}',
                      'ทั้งหมด',
                      Icons.chat_bubble_outline,
                    ),
                    _buildStatItem(
                      '${allChatRooms.where((r) => r.status == ChatStatus.waiting).length}',
                      'รอดำเนินการ',
                      Icons.pending_outlined,
                    ),
                    _buildStatItem(
                      '${allChatRooms.where((r) => r.status == ChatStatus.active).length}',
                      'กำลังแชท',
                      Icons.chat,
                    ),
                    _buildStatItem(
                      '${allChatRooms.where((r) => r.unreadByAdmin > 0).length}',
                      'ยังไม่อ่าน',
                      Icons.mark_email_unread,
                    ),
                  ],
                ),
              ),

              // Search Results Info
              if (_searchQuery.isNotEmpty)
                _buildSearchResults(chatRooms, allChatRooms)
              else if (_currentInput.isNotEmpty && _currentInput != _searchQuery)
                _buildPendingSearchIndicator(),

              // Chat Rooms List
              Expanded(
                child: chatRooms.isEmpty ? _buildEmptyState() : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: chatRooms.length,
                  itemBuilder: (context, index) {
                    return _buildChatRoomCard(chatRooms[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Filter chat rooms based on selected filter
  List<ChatRoom> _filterChatRooms(List<ChatRoom> chatRooms) {
    switch (_selectedFilter) {
      case 'waiting':
        return chatRooms.where((r) => r.status == ChatStatus.waiting).toList();
      case 'active':
        return chatRooms.where((r) => r.status == ChatStatus.active).toList();
      case 'resolved':
        return chatRooms.where((r) => r.status == ChatStatus.resolved).toList();
      case 'closed':
        return chatRooms.where((r) => r.status == ChatStatus.closed).toList();
      case 'unread':
        return chatRooms.where((r) => r.unreadByAdmin > 0).toList();
      default:
        return chatRooms;
    }
  }

  // Search chat rooms
  List<ChatRoom> _searchChatRooms(List<ChatRoom> chatRooms) {
    print('🔍 Searching with query: "$_searchQuery" in ${chatRooms.length} rooms'); // Debug
    
    if (_searchQuery.isEmpty) {
      return chatRooms;
    }
    
    final query = _searchQuery.toLowerCase();
    final results = chatRooms.where((room) {
      final nameMatch = room.customerName.toLowerCase().contains(query);
      final emailMatch = room.customerEmail.toLowerCase().contains(query);
      final messageMatch = room.lastMessage?.toLowerCase().contains(query) ?? false;
      final adminMatch = room.assignedAdminName?.toLowerCase().contains(query) ?? false;
      
      return nameMatch || emailMatch || messageMatch || adminMatch;
    }).toList();
    
    print('🔍 Found ${results.length} results'); // Debug
    return results;
  }

  // Build search bar
  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            enabled: true, // Make sure it's enabled
            readOnly: false, // Make sure it's not read-only
            onChanged: (value) {
              print('🔍 Search input: $value'); // Debug
              
              // Cancel previous timer
              _debounceTimer?.cancel();
              
              // Update current input immediately (for display)
              _currentInput = value;
              
              // Set suggestions immediately for better UX
              _suggestionsNotifier.value = value.isNotEmpty;
              
              // Don't auto-search while typing, wait for Enter or search button
            },
            onSubmitted: (value) {
              print('🔍 Search submitted: $value'); // Debug
              _performSearch(value);
            },
            onTap: () {
              print('🔍 Search field tapped'); // Debug
              // Use ValueNotifier to avoid rebuilding entire widget
              if (_searchQuery.isNotEmpty) {
                _suggestionsNotifier.value = true;
              }
            },
            decoration: InputDecoration(
              hintText: 'ค้นหาตามชื่อลูกค้า, อีเมล, ข้อความ...',
              prefixIcon: InkWell(
                onTap: () {
                  if (_currentInput.isNotEmpty) {
                    _performSearch(_currentInput);
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.search,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              suffixIcon: _currentInput.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Color(0xFF94A3B8),
                      ),
                      onPressed: () {
                        _debounceTimer?.cancel();
                        _searchController.clear();
                        _suggestionsNotifier.value = false;
                        setState(() {
                          _searchQuery = '';
                          _currentInput = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintStyle: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
          ),
          
          // Search Suggestions using ValueListenableBuilder
          ValueListenableBuilder<bool>(
            valueListenable: _suggestionsNotifier,
            builder: (context, showSuggestions, child) {
              if (!showSuggestions || _recentSearches.isEmpty) {
                return SizedBox.shrink();
              }
              
              return Container(
                margin: EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'การค้นหาล่าสุด',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ..._recentSearches.map((search) => InkWell(
                      onTap: () {
                        _debounceTimer?.cancel();
                        _searchController.text = search;
                        _suggestionsNotifier.value = false;
                        setState(() {
                          _searchQuery = search;
                          _currentInput = search;
                        });
                        _searchFocusNode.unfocus();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                search,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.north_west,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Build filter tabs
  Widget _buildFilterTabs(List<ChatRoom> allChatRooms) {
    final filters = [
      {'key': 'all', 'label': 'ทั้งหมด', 'count': allChatRooms.length},
      {'key': 'waiting', 'label': 'รอดำเนินการ', 'count': allChatRooms.where((r) => r.status == ChatStatus.waiting).length},
      {'key': 'active', 'label': 'กำลังแชท', 'count': allChatRooms.where((r) => r.status == ChatStatus.active).length},
      {'key': 'unread', 'label': 'ยังไม่อ่าน', 'count': allChatRooms.where((r) => r.unreadByAdmin > 0).length},
    ];

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['key'];
          
          return Container(
            margin: EdgeInsets.only(right: 12),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${filter['label']}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Color(0xFF64748B),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (filter['count'] as int > 0) ...[
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white.withOpacity(0.3)
                            : Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${filter['count']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['key'] as String;
                });
              },
              selectedColor: Color(0xFF6366F1),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? Color(0xFF6366F1) : Color(0xFFE2E8F0),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  // Build pending search indicator
  Widget _buildPendingSearchIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF64748B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF64748B).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: Color(0xFF64748B),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'พิมพ์ "${_currentInput}" แล้วกด Enter หรือคลิกปุ่มค้นหาเพื่อค้นหา',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _performSearch(_currentInput),
              child: Text(
                'ค้นหา',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build search results info
  Widget _buildSearchResults(List<ChatRoom> searchResults, List<ChatRoom> totalRooms) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: Color(0xFF6366F1),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'พบ ${searchResults.length} ผลลัพธ์จากทั้งหมด ${totalRooms.length} แชท สำหรับ "${_searchQuery}"',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              _debounceTimer?.cancel();
              _searchController.clear();
              _suggestionsNotifier.value = false;
              setState(() {
                _searchQuery = '';
                _currentInput = '';
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ล้าง',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build empty state
  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      // No search results
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'ไม่พบผลลัพธ์',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'ลองค้นหาด้วยคำอื่น หรือเปลี่ยนฟิลเตอร์',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _debounceTimer?.cancel();
                _searchController.clear();
                _suggestionsNotifier.value = false;
                setState(() {
                  _searchQuery = '';
                  _currentInput = '';
                  _selectedFilter = 'all';
                });
              },
              icon: Icon(Icons.refresh, size: 16),
              label: Text('รีเซ็ตการค้นหา'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // No chat rooms at all
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'ยังไม่มีแชท',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'เมื่อลูกค้าเริ่มแชทจะแสดงที่นี่',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildChatRoomCard(ChatRoom chatRoom) {
    final hasUnreadMessages = chatRoom.unreadByAdmin > 0;
    final isWaiting = chatRoom.status == ChatStatus.waiting;
    final isActive = chatRoom.status == ChatStatus.active;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: hasUnreadMessages ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasUnreadMessages ? Color(0xFFEF4444) : Colors.transparent,
          width: hasUnreadMessages ? 1 : 0,
        ),
      ),
      child: InkWell(
        onTap: () => _openAdminChatRoom(chatRoom),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: hasUnreadMessages ? Color(0xFFFEF2F2) : Colors.white,
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Customer Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getStatusColor(chatRoom.status).withOpacity(0.1),
                    child: Text(
                      chatRoom.customerName.isNotEmpty 
                          ? chatRoom.customerName[0].toUpperCase()
                          : 'C',
                      style: TextStyle(
                        color: _getStatusColor(chatRoom.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Customer Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              chatRoom.customerName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            if (chatRoom.isCustomerOnline) ...[
                              SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          chatRoom.customerEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Priority and Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Priority indicator
                      if (isWaiting)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ด่วน',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      SizedBox(height: 4),
                      // Status Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(chatRoom.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          chatRoom.status.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              if (chatRoom.lastMessage != null) ...[
                SizedBox(height: 12),
                // Last Message
                Text(
                  chatRoom.lastMessage!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              SizedBox(height: 12),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(width: 4),
                      Text(
                        chatRoom.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      if (hasUnreadMessages) ...[
                        SizedBox(width: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.priority_high,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'ตอบด่วน',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      if (chatRoom.assignedAdminName != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'รับโดย: ${chatRoom.assignedAdminName}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (chatRoom.unreadByAdmin > 0) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${chatRoom.unreadByAdmin}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      // Quick action buttons
                      if (isWaiting || isActive) ...[
                        InkWell(
                          onTap: () => _quickReply(chatRoom),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.reply,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'ตอบกลับ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ChatStatus status) {
    switch (status) {
      case ChatStatus.waiting:
        return Color(0xFFF59E0B);
      case ChatStatus.active:
        return Color(0xFF10B981);
      case ChatStatus.resolved:
        return Color(0xFF6366F1);
      case ChatStatus.closed:
        return Color(0xFF64748B);
    }
  }

  void _openAdminChatRoom(ChatRoom chatRoom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminChatRoomPage(chatRoom: chatRoom),
      ),
    );
  }

  // Quick reply function
  void _quickReply(ChatRoom chatRoom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QuickReplyModal(chatRoom: chatRoom),
    );
  }
}

class AdminChatRoomPage extends StatefulWidget {
  final ChatRoom chatRoom;

  AdminChatRoomPage({required this.chatRoom});

  @override
  _AdminChatRoomPageState createState() => _AdminChatRoomPageState();
}

class _AdminChatRoomPageState extends State<AdminChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasAssignedSelf = false;

  @override
  void initState() {
    super.initState();
    _joinChatRoom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    ChatService.leaveChatRoom(widget.chatRoom.id, true);
    super.dispose();
  }

  Future<void> _joinChatRoom() async {
    await ChatService.joinChatRoom(widget.chatRoom.id, true);
    await ChatService.markMessagesAsRead(widget.chatRoom.id, true);

    // Auto-assign if waiting
    if (widget.chatRoom.status == ChatStatus.waiting && !_hasAssignedSelf) {
      _assignToSelf();
    }
  }

  Future<void> _assignToSelf() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final firebaseUser = authProvider.user;

    final adminId = user?.id ?? firebaseUser?.uid ?? '';
    final adminName = user?.displayName ?? user?.name ?? firebaseUser?.displayName ?? 'Admin';

    try {
      await ChatService.assignAdminToChatRoom(
        roomId: widget.chatRoom.id,
        adminId: adminId,
        adminName: adminName,
      );
      setState(() {
        _hasAssignedSelf = true;
      });
    } catch (e) {
      print('Error assigning admin: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final firebaseUser = authProvider.user;

    final senderId = user?.id ?? firebaseUser?.uid ?? '';
    final senderName = user?.displayName ?? user?.name ?? firebaseUser?.displayName ?? 'Admin';
    final message = _messageController.text.trim();

    _messageController.clear();

    try {
      await ChatService.sendMessage(
        chatRoomId: widget.chatRoom.id,
        senderId: senderId,
        senderName: senderName,
        senderRole: 'admin',
        message: message,
      );

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatRoom.customerName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              widget.chatRoom.isCustomerOnline ? 'ออนไลน์' : 'ออฟไลน์',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'close':
                  _showCloseDialog();
                  break;
                case 'info':
                  _showCustomerInfo();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('ข้อมูลลูกค้า'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'close',
                child: Row(
                  children: [
                    Icon(Icons.close, color: Colors.red),
                    SizedBox(width: 8),
                    Text('ปิดแชท', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages Area
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService.getChatMessages(widget.chatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                // Auto scroll when new message arrives
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
                        hintText: 'ตอบกลับลูกค้า...',
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
    final isFromAdmin = message.senderRole == 'admin';
    final isSystem = message.senderRole == 'system';

    if (isSystem) {
      return _buildSystemMessage(message);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isFromAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFromAdmin) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF10B981).withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 16,
                color: Color(0xFF10B981),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isFromAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isFromAdmin)
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
                    color: isFromAdmin ? Color(0xFF6366F1) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(isFromAdmin ? 18 : 4),
                      bottomRight: Radius.circular(isFromAdmin ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // แสดงรูปภาพถ้ามี
                      if (message.type == ChatMessageType.image && message.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            message.imageUrl!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isFromAdmin ? Colors.white.withOpacity(0.8) : Color(0xFF6366F1),
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
                                  color: (isFromAdmin ? Colors.white : Color(0xFF6366F1)).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: isFromAdmin ? Colors.white.withOpacity(0.7) : Color(0xFF6366F1).withOpacity(0.7),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'ไม่สามารถโหลดรูปภาพได้',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isFromAdmin ? Colors.white.withOpacity(0.7) : Color(0xFF6366F1).withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (message.message.isNotEmpty) SizedBox(height: 8),
                      ],
                      // แสดงข้อความ
                      if (message.message.isNotEmpty)
                        Text(
                          message.message,
                          style: TextStyle(
                            fontSize: 16,
                            color: isFromAdmin ? Colors.white : Color(0xFF1E293B),
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
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
          if (isFromAdmin) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF6366F1).withOpacity(0.1),
              child: Icon(
                Icons.support_agent,
                size: 16,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ],
      ),
    );
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

  void _showCloseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ปิดแชท'),
        content: Text('คุณต้องการปิดแชทนี้หรือไม่? ลูกค้าจะไม่สามารถส่งข้อความเพิ่มได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ChatService.closeChatRoom(widget.chatRoom.id, 'ปิดโดย Admin');
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ไม่สามารถปิดแชทได้: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('ปิดแชท', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCustomerInfo() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ข้อมูลลูกค้า',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow('ชื่อ', widget.chatRoom.customerName),
            _buildInfoRow('อีเมล', widget.chatRoom.customerEmail),
            _buildInfoRow('สถานะ', widget.chatRoom.isCustomerOnline ? 'ออนไลน์' : 'ออฟไลน์'),
            _buildInfoRow('เริ่มแชท', widget.chatRoom.formattedDate),
            _buildInfoRow('สถานะแชท', widget.chatRoom.statusDisplay),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickReplyModal extends StatefulWidget {
  final ChatRoom chatRoom;
  
  QuickReplyModal({required this.chatRoom});
  
  @override
  _QuickReplyModalState createState() => _QuickReplyModalState();
}

class _QuickReplyModalState extends State<QuickReplyModal> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _quickMessages = [
    'สวัสดีครับ ทางเราจะช่วยเหลือท่านในเรื่องใดครับ?',
    'ขอบคุณสำหรับการติดต่อ กำลังตรวจสอบข้อมูลให้ท่าน',
    'ท่านสามารถอธิบายปัญหาให้เราฟังได้เพิ่มเติมไหมครับ?',
    'ขออภัยในความไม่สะดวก กำลังแก้ไขปัญหาให้ท่าน',
    'ขอบคุณสำหรับข้อมูล เราจะดำเนินการตรวจสอบให้ท่าน',
  ];
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF10B981).withOpacity(0.1),
                  child: Text(
                    widget.chatRoom.customerName.isNotEmpty 
                        ? widget.chatRoom.customerName[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ตอบกลับ: ${widget.chatRoom.customerName}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        widget.chatRoom.customerEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          Divider(),
          
          // Quick Messages
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ข้อความด่วน',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  ...(_quickMessages.map((message) => Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _sendQuickMessage(message),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ))).toList(),
                  
                  SizedBox(height: 20),
                  
                  Text(
                    'ข้อความกำหนดเอง',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Custom message input
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความของคุณ...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _sendCustomMessage(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6366F1),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'ส่งข้อความ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _sendQuickMessage(String message) async {
    await _sendMessage(message);
  }
  
  Future<void> _sendCustomMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    await _sendMessage(_messageController.text.trim());
  }
  
  Future<void> _sendMessage(String message) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      final firebaseUser = authProvider.user;

      final senderId = user?.id ?? firebaseUser?.uid ?? '';
      final senderName = user?.displayName ?? user?.name ?? firebaseUser?.displayName ?? 'Admin';

      await ChatService.sendMessage(
        chatRoomId: widget.chatRoom.id,
        senderId: senderId,
        senderName: senderName,
        senderRole: 'admin',
        message: message,
      );

      Navigator.pop(context); // Close modal
      
      // Navigate to full chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminChatRoomPage(chatRoom: widget.chatRoom),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถส่งข้อความได้: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
