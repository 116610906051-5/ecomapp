import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/google_drive_oauth_service.dart';

class GoogleDriveAuthDialog extends StatefulWidget {
  @override
  _GoogleDriveAuthDialogState createState() => _GoogleDriveAuthDialogState();
}

class _GoogleDriveAuthDialogState extends State<GoogleDriveAuthDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _authUrl;

  @override
  void initState() {
    super.initState();
    _authUrl = GoogleDriveOAuthService.getAuthorizationUrl();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _authorize() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอก Authorization Code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await GoogleDriveOAuthService.exchangeCodeForToken(_codeController.text.trim());
      
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ เชื่อมต่อ Google Drive สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ไม่สามารถเชื่อมต่อ Google Drive ได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyUrl() {
    if (_authUrl != null) {
      Clipboard.setData(ClipboardData(text: _authUrl!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📋 คัดลอก URL แล้ว'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '🔗 เชื่อมต่อ Google Drive',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ขั้นตอนการเชื่อมต่อ:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 12),
            
            _buildStep('1', 'คัดลอก URL ด้านล่าง', Icons.copy),
            _buildStep('2', 'เปิดในเบราว์เซอร์', Icons.open_in_browser),
            _buildStep('3', 'ล็อกอิน Google และอนุญาต', Icons.login),
            _buildStep('4', 'คัดลอก Authorization Code', Icons.code),
            _buildStep('5', 'วางใส่ช่องด้านล่างและกด OK', Icons.check),
            
            SizedBox(height: 16),
            
            // Authorization URL
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                border: Border.all(color: Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Authorization URL:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _copyUrl,
                        icon: Icon(Icons.copy, size: 16),
                        label: Text('คัดลอก'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    _authUrl ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontFamily: 'monospace',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Authorization Code Input
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Authorization Code',
                hintText: 'วาง Authorization Code ที่ได้จากเบราว์เซอร์',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
              maxLines: 2,
              enabled: !_isLoading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _authorize,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text('เชื่อมต่อ'),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Icon(icon, size: 16, color: Color(0xFF6366F1)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
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
}
