import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as AuthProv;

class PersonalInformationPage extends StatefulWidget {
  @override
  _PersonalInformationPageState createState() => _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();

  
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProv.AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final firebaseUser = authProvider.user;

    _displayNameController.text = user?.displayName ?? user?.name ?? firebaseUser?.displayName ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
    // Address field removed since AppUser doesn't have direct address field
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProv.AuthProvider>(context, listen: false);
      final firebaseUser = FirebaseAuth.instance.currentUser;

      // Update Firebase display name (with error handling for plugin issues)
      try {
        if (firebaseUser != null && _displayNameController.text.trim().isNotEmpty) {
          await firebaseUser.updateDisplayName(_displayNameController.text.trim());
          await firebaseUser.reload();
        }
      } catch (e) {
        print('⚠️ Firebase Auth updateDisplayName failed (plugin issue): $e');
        // Continue with local update even if Firebase Auth fails
      }

      // Update local user data
      await authProvider.updateUserProfile(
        displayName: _displayNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัพเดทข้อมูลสำเร็จ!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Color(0xFF6366F1),
        elevation: 0,
        title: Text(
          'ข้อมูลส่วนตัว',
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
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: Consumer<AuthProv.AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          final firebaseUser = authProvider.user;

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Color(0xFF6366F1).withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFF6366F1).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFF6366F1),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 32),

                  // Personal Information Form
                  _buildSectionTitle('ข้อมูลทั่วไป'),
                  SizedBox(height: 16),

                  _buildFormField(
                    label: 'ชื่อผู้ใช้',
                    controller: _displayNameController,
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกชื่อผู้ใช้';
                      }
                      if (value.trim().length < 2) {
                        return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 2 ตัวอักษร';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  _buildFormField(
                    label: 'หมายเลขโทรศัพท์',
                    controller: _phoneController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (value.trim().length < 10) {
                          return 'หมายเลขโทรศัพท์ไม่ถูกต้อง';
                        }
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 24),

                  // Account Information (Read-only)
                  _buildSectionTitle('ข้อมูลบัญชี'),
                  SizedBox(height: 16),

                  _buildReadOnlyField('อีเมล', firebaseUser?.email ?? user?.email ?? 'ไม่มีอีเมล'),
                  SizedBox(height: 12),
                  _buildReadOnlyField('สถานะการยืนยัน', 
                    firebaseUser?.emailVerified == true ? 'ยืนยันแล้ว ✅' : 'ยังไม่ได้ยืนยัน ⚠️'),
                  SizedBox(height: 12),
                  _buildReadOnlyField('เข้าร่วมเมื่อ', 
                    firebaseUser?.metadata.creationTime != null 
                      ? _formatDate(firebaseUser!.metadata.creationTime!) 
                      : 'ไม่ทราบ'),

                  SizedBox(height: 32),

                  // Action Buttons
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () {
                              setState(() {
                                _isEditing = false;
                                _loadUserData(); // Reset form data
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Color(0xFF64748B)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'ยกเลิก',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6366F1),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'บันทึก',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }
}
