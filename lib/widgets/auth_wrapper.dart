import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../pages/login_page.dart';
import 'main_navigation.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading spinner while checking auth state
        if (authProvider.isLoading) {
          return Scaffold(
            backgroundColor: Color(0xFF6366F1),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // If user is authenticated, show main app
        if (authProvider.isAuthenticated) {
          return MainNavigation();
        }

        // If user is not authenticated, show login page
        return LoginPage();
      },
    );
  }
}
