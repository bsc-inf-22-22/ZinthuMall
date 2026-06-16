// =============================================================
// FILE: lib/features/admin/presentation/screens/admin_login_screen.dart
//
// PURPOSE:
//   The admin login screen. Only one person (the store owner)
//   uses this. After login, they go to the Admin Dashboard.
//
//   WHAT YOU LEARN HERE:
//   - TextEditingController — reads text from input fields
//   - Form + GlobalKey<FormState> — validates inputs
//   - Riverpod ref.read() — write to state (vs ref.watch to read)
//   - Simulating an API call with Future.delayed()
//   - Navigator.pushReplacement() — navigate without back button
//
//   MOCK AUTH (now):
//   email: admin@kachipapa.mw  password: admin123
//   REAL AUTH (later):
//   POST /auth/login → { access_token: "..." }
//   Store token → use on every protected request
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/providers/products_provider.dart';
import '../../../../../core/services/api_service.dart';
import 'admin_dashboard_screen.dart';
import 'admin_register_screen.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  // ConsumerStatefulWidget = StatefulWidget that can use Riverpod
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  // ----------------------------------------------------------
  // FORM KEY
  // A GlobalKey uniquely identifies the Form widget.
  // We use it to call _formKey.currentState!.validate()
  // which triggers all the validators in the form.
  // ----------------------------------------------------------
  final _formKey = GlobalKey<FormState>();

  // ----------------------------------------------------------
  // TEXT CONTROLLERS
  // Each controller is linked to one TextField.
  // controller.text gives you what the user typed.
  // Always dispose() controllers to free memory.
  // ----------------------------------------------------------
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  // Local UI state
  bool _isPasswordVisible = false;
  bool _isLoading         = false;
  String? _errorMessage;

  @override
  void dispose() {
    // Free memory when screen is removed from widget tree
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // LOGIN METHOD
  // Now: checks hardcoded credentials
  // Later: POST /auth/login and store JWT token
  // ----------------------------------------------------------
  Future<void> _login() async {
    // 1. Clear previous error
    setState(() => _errorMessage = null);

    // 2. Validate all form fields — runs each field's validator
    if (!_formKey.currentState!.validate()) return;

    // 3. Show loading spinner
    setState(() => _isLoading = true);

    try {
      // REAL API call to NestJS backend
      // POST /api/admin/auth/login → { access_token: "..." }
      final email    = _emailController.text.trim();
      final password = _passwordController.text;

      final api = ApiService();
      await api.loginAdmin(email: email, password: password);
      // loginAdmin() saves the token to SharedPreferences automatically

      // Save auth state in Riverpod
      ref.read(adminAuthProvider.notifier).state  = true;
      ref.read(adminNameProvider.notifier).state  = 'Store Admin';
      ref.read(adminEmailProvider.notifier).state = email;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } on ApiException catch (e) {
      // ApiException gives us readable messages like "Authentication failed"
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Connection failed. Is the backend running?');
    } finally {
      // Always hide loading, even if there was an error
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Row(
        children: [
          // LEFT PANEL — branding (hidden on small screens)
          if (MediaQuery.of(context).size.width > 700)
            _buildLeftPanel(),

          // RIGHT PANEL — login form
          Expanded(child: _buildLoginForm()),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // LEFT BRAND PANEL
  // ----------------------------------------------------------
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
          // Logo
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Kachipapa',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: 'Store',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentOrange,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Admin\nControl Panel',
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your products, track orders, and grow your business across Malawi.',
            style: GoogleFonts.dmSans(
              color: Colors.white60,
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 32),
          // Feature list
          ...[
            ('📦', 'Add & manage products'),
            ('🗑️', 'Remove listings instantly'),
            ('📊', 'View sales stats'),
            ('📱', 'Payments via Pachangu'),
          ].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(
                      item.$2,
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )),
          const Spacer(),
          Text(
            '🇲🇼 Made in Malawi · Powered by Pachangu',
            style: GoogleFonts.dmSans(
              color: Colors.white30,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // LOGIN FORM
  // ----------------------------------------------------------
  Widget _buildLoginForm() {
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
                Text(
                  'Welcome back 👋',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your admin account',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // HINT BOX (remove in production)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB7EFD0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.successGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demo: admin@kachipapa.mw / admin123',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // EMAIL FIELD
                _buildLabel('Email Address'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    hint: 'admin@kachipapa.mw',
                    icon: Icons.email_outlined,
                  ),
                  // validator runs when _formKey.currentState!.validate()
                  // return null = valid, return String = error message
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null; // valid
                  },
                ),
                const SizedBox(height: 16),

                // PASSWORD FIELD
                _buildLabel('Password'),
                TextFormField(
                  controller: _passwordController,
                  // obscureText hides the password characters
                  obscureText: !_isPasswordVisible,
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    icon: Icons.lock_outlined,
                    suffix: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppTheme.textHint,
                      ),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  // pressing Enter on keyboard triggers login
                  onFieldSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 8),

                // ERROR MESSAGE
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
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
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.dmSans(
                            color: AppTheme.primaryRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // REGISTER LINK
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminRegisterScreen()),
                    ),
                    child: Text(
                      "Don't have an account? Register",
                      style: GoogleFonts.dmSans(
                        color: AppTheme.primaryRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // BACK TO STORE
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back,
                        size: 16, color: AppTheme.textHint),
                    label: Text(
                      'Back to Store',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.textHint,
                        fontSize: 13,
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

  // ----------------------------------------------------------
  // HELPERS
  // ----------------------------------------------------------
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.3,
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
