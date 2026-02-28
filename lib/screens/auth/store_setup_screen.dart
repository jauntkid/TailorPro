import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/store.dart';
import '../../services/store_service.dart';

/// Screen shown after login if user has no store linked.
/// Allows creating a new store or joining an existing one.
class StoreSetupScreen extends StatefulWidget {
  final String uid;
  final String email;
  final String displayName;
  final void Function(Store store) onStoreReady;
  final VoidCallback onSignOut;

  const StoreSetupScreen({
    super.key,
    required this.uid,
    required this.email,
    required this.displayName,
    required this.onStoreReady,
    required this.onSignOut,
  });

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> {
  static const _gold = Color(0xFFD4A574);
  final _storeService = StoreService();

  bool _isCreating = true; // true = create tab, false = join tab
  bool _isLoading = false;
  String? _error;

  // Create store
  final _storeNameCtrl = TextEditingController();

  // Join store
  final _storeIdCtrl = TextEditingController();

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _storeIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _createStore() async {
    final name = _storeNameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a store name');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final store = await _storeService.createStore(
        uid: widget.uid,
        email: widget.email,
        storeName: name,
      );
      if (mounted) widget.onStoreReady(store);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to create store: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinStore() async {
    final id = _storeIdCtrl.text.trim().toUpperCase();
    if (id.isEmpty) {
      setState(() => _error = 'Enter a store ID');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final store = await _storeService.joinStore(
        storeId: id,
        uid: widget.uid,
        email: widget.email,
      );
      if (!mounted) return;
      if (store == null) {
        setState(() {
          _error =
              'Store not found or your email is not in the allowed list.\nAsk the store owner to add "${widget.email}".';
          _isLoading = false;
        });
      } else {
        widget.onStoreReady(store);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to join store: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/images/logo.png',
                    width: 64, height: 64, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              const Text(
                'GODUKAAN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  color: _gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome, ${widget.displayName}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Set Up Your Store',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new store or join an existing one',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 28),

              // Tab selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: 'Create New',
                        isActive: _isCreating,
                        onTap: () => setState(() {
                          _isCreating = true;
                          _error = null;
                        }),
                      ),
                    ),
                    Expanded(
                      child: _TabButton(
                        label: 'Join Store',
                        isActive: !_isCreating,
                        onTap: () => setState(() {
                          _isCreating = false;
                          _error = null;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Create form
              if (_isCreating) ...[
                TextField(
                  controller: _storeNameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      _inputDeco('Store Name', Icons.storefront_rounded),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                Text(
                  'You\'ll be the owner of this store and can invite team members.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],

              // Join form
              if (!_isCreating) ...[
                TextField(
                  controller: _storeIdCtrl,
                  style: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _inputDeco('Store ID', Icons.vpn_key_rounded),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the 8-character store ID provided by the store owner.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],

              // Error
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading
                      ? null
                      : (_isCreating ? _createStore : _joinStore),
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: _gold.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          _isCreating ? 'Create Store' : 'Join Store',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Sign out link
              TextButton(
                onPressed: _isLoading ? null : widget.onSignOut,
                child: const Text(
                  'Sign out',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                ),
              ),
            ],
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFD4A574).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color:
                  isActive ? const Color(0xFFD4A574) : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}
