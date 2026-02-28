import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFD4A574);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    AuthResult result;
    if (_isSignUp) {
      result = await widget.authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
    } else {
      result = await widget.authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _error = result.error;
        _isLoading = false;
      });
    }
    // Success → auth state listener in main.dart will navigate away
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await widget.authService.signInWithGoogle();
    if (!mounted) return;
    if (!result.success && result.error != 'Cancelled') {
      setState(() {
        _error = result.error;
        _isLoading = false;
      });
    } else if (!result.success) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter your email first');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await widget.authService.resetPassword(email);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } else {
      setState(() => _error = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ─── Brand ──────────────────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_gold, Color(0xFFB8956A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset('assets/images/logo.png',
                          width: 36, height: 36, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'GODUKAAN',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      color: _gold,
                    ),
                  ),
                  const Text(
                    'STORE MANAGER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 4,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ─── Name (sign up) ─────────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _isSignUp
                        ? Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: _inputDeco(
                                    'Full Name', Icons.person_outline),
                                style: const TextStyle(color: Colors.white),
                                validator: _isSignUp
                                    ? (v) => v == null || v.trim().isEmpty
                                        ? 'Required'
                                        : null
                                    : null,
                              ),
                              const SizedBox(height: 14),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ─── Email ──────────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDeco('Email', Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Valid email required'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // ─── Password ───────────────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    decoration:
                        _inputDeco('Password', Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF555555),
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),

                  // ─── Error ──────────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ─── Forgot password ────────────────────────────
                  if (!_isSignUp) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _forgotPassword,
                        child: const Text('Forgot Password?',
                            style: TextStyle(
                                color: Color(0xFF888888), fontSize: 13)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ─── Submit ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: _gold.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              _isSignUp ? 'Create Account' : 'Sign In',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Divider ────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFF333333))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or',
                            style: TextStyle(
                                color: Color(0xFF555555), fontSize: 13)),
                      ),
                      const Expanded(child: Divider(color: Color(0xFF333333))),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ─── Google ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _googleSignIn,
                      icon: const Text('G',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Color(0xFF333333)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Toggle ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? 'Already have an account? '
                            : "Don't have an account? ",
                        style: const TextStyle(
                            color: Color(0xFF666666), fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => setState(() {
                                  _isSignUp = !_isSignUp;
                                  _error = null;
                                }),
                        child: Text(
                          _isSignUp ? 'Sign In' : 'Sign Up',
                          style: const TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555)),
        prefixIcon: Icon(icon, color: const Color(0xFF555555), size: 20),
        filled: true,
        fillColor: const Color(0xFF141414),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF222222)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF222222)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}
