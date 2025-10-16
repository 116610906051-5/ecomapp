import 'package:flutter/material.dart';

class FirestoreInstructionsDialog extends StatelessWidget {
  const FirestoreInstructionsDialog({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const FirestoreInstructionsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          SizedBox(width: 8),
          Text('Firestore Setup Required'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To enable full functionality, please set up Firestore:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            _buildStep('1', 'Go to Firebase Console'),
            _buildStep('2', 'Open console.firebase.google.com'),
            _buildStep('3', 'Select project "ecom-f2856"'),
            _buildStep('4', 'Click "Firestore Database"'),
            _buildStep('5', 'Click "Create database"'),
            _buildStep('6', 'Select "Start in test mode"'),
            _buildStep('7', 'Choose location (e.g., us-central1)'),
            _buildStep('8', 'Click "Done" and restart the app'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The app will work with sample data until Firestore is enabled.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Got it!'),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String instruction) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                instruction,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
