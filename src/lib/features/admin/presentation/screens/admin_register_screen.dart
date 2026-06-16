// =============================================================
// FILE: lib/features/admin/presentation/screens/admin_register_screen.dart
//
// PURPOSE:
//   One-time admin registration screen.
//   Calls POST /api/admin/auth/register
//   After successful registration, navigates to login screen.
//
// NOTE: The backend only allows ONE admin to register.
//   Second attempt returns 409 Conflict.
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/api_service.dart';
import 'admin_login_screen.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _emailController  = TextEditingController();
  final _passwordController    = TextEditingController();
  final _confirmController     = TextEditingController();

  bool _isPasswordVisible        = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading                = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      await api.registerAdmin(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Show success then go to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Admin account created! Please sign in.',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      );

    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() =>
          _errorMessage = 'Connection failed. Is the backend running?');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 700) _buildLeftPanel(),
          Expanded(child: _buildForm()),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 380,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF3D0012)],
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Kachipapa',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28, fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: 'Store',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28, fontWeight: FontWeight.w700,
                    color: AppTheme.accentOrange,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Create Your\nAdmin Account',
            style: GoogleFonts.playfairDisplay(
              fontSize: 36, fontWeight: FontWeight.w700,
              color: Colors.white, height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Register once to get full access to the store dashboard.',
            style: GoogleFonts.dmSans(
              color: Colors.white60, fontSize: 14, height: 1.7,
            ),
          ),
          const SizedBox(height: 32),
          ...[ 
            ('📦', 'Manage products'),
            ('📊', 'View analytics'),
            ('🗑️', 'Control listings'),
            ('📱', 'Pachangu payments'),
          ].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Text(item.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(item.$2,
                  style: GoogleFonts.dmSans(
                    color: Colors.white70, fontSize: 14,
                  ),
                ),
              ],
            ),
          )),
          const Spacer(),
          Text(
            '🇲🇼 Made in Malawi · Powered by Pachangu',
            style: GoogleFonts.dmSans(color: Colors.white30, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Account 🎉',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Set up your Kachipapa admin account',
                  style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // EMAIL
                _buildLabel('Email Address'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    hint: 'admin@kachipapa.mw',
                    icon: Icons.email_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // PASSWORD
                _buildLabel('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    icon: Icons.lock_outlined,
                    suffix: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20, color: AppTheme.textHint,
                      ),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a password';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // CONFIRM PASSWORD
                _buildLabel('Confirm Password'),
                TextFormField(
                  controller: _confirmController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    icon: Icons.lock_outlined,
                    suffix: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20, color: AppTheme.textHint,
                      ),
                      onPressed: () => setState(() =>
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                  onFieldSubmitted: (_) => _register(),
                ),

                // ERROR MESSAGE
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.primaryRed.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.primaryRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!,
                            style: GoogleFonts.dmSans(
                              color: AppTheme.primaryRed, fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // REGISTER BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2,
                            ),
                          )
                        : Text('Create Account',
                            style: GoogleFonts.dmSans(
                              fontSize: 15, fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // ALREADY HAVE ACCOUNT
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminLoginScreen()),
                    ),
                    child: Text(
                      'Already have an account? Sign in',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.primaryRed, fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
        style: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary, letterSpacing: 0.3,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textHint),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF4F4F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: AppTheme.primaryRed.withOpacity(0.5), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.5),
      ),
    );
  }
}
