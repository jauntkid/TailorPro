import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _showRetryButton = false;
  bool _isCheckingAuth = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    setState(() {
      _isCheckingAuth = true;
      _showRetryButton = false;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Wait for animation to complete
      await Future.delayed(const Duration(seconds: 2));

      final isLoggedIn = await authProvider.isLoggedIn();

      if (isLoggedIn) {
        // Check if token is valid by calling an API endpoint
        try {
          final result = await authProvider.checkAuthStatus();
          if (authProvider.isAuthenticated) {
            // If authenticated, navigate to home
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            // If not authenticated (token invalid/expired), navigate to login
            Navigator.pushReplacementNamed(context, '/login');
          }
        } catch (e) {
          print("Auth check error: $e");
          setState(() {
            _showRetryButton = true;
            _isCheckingAuth = false;
          });
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print("Error in auth check: $e");
      setState(() {
        _showRetryButton = true;
        _isCheckingAuth = false;
      });
    }
  }

  void _resetAuthAndNavigateToLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.resetAuth();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _animation,
              child: const Text(
                'SIRI',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _animation,
              child: const Text(
                'Tailor App',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 60),
            if (_showRetryButton) ...[
              const Text(
                'Authentication Error',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _checkLoginStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _resetAuthAndNavigateToLogin,
                    child: const Text(
                      'Go to Login',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ] else if (_isCheckingAuth) ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
