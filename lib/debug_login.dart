import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugLoginPage extends StatefulWidget {
  const DebugLoginPage({super.key});

  @override
  State<DebugLoginPage> createState() => _DebugLoginPageState();
}

class _DebugLoginPageState extends State<DebugLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';

  @override
  void initState() {
    super.initState();
    // Set admin credentials for testing
    _emailController.text = 'pang@gmail.com';
    _passwordController.text = '';
  }

  Future<void> _testDirectLogin() async {
    try {
      setState(() {
        _message = 'Attempting direct Firebase login...';
      });

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _message = 'SUCCESS! Logged in as: ${userCredential.user?.email}';
      });
    } catch (e) {
      setState(() {
        _message = 'ERROR: $e';
      });
    }
  }

  Future<void> _testListUsers() async {
    try {
      setState(() {
        _message = 'Checking current user...';
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() {
          _message = 'Already signed in: ${currentUser.email}';
        });
      } else {
        setState(() {
          _message = 'No user currently signed in';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'ERROR checking user: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Login'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testDirectLogin,
              child: const Text('Test Direct Login'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testListUsers,
              child: const Text('Check Current User'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                setState(() {
                  _message = 'Signed out';
                });
              },
              child: const Text('Sign Out'),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
