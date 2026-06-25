// =============================================================
// FILE: lib/features/auth/presentation/screens/customer_auth_screen.dart
//
// Customer Login + Register screen (separate from admin login).
// Toggles between Login and Register tabs.
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class CustomerAuthScreen extends StatefulWidget {
  final bool startOnRegister;
  const CustomerAuthScreen({super.key, this.startOnRegister = false});

  @override
  State<CustomerAuthScreen> createState() => _CustomerAuthScreenState();
}

class _CustomerAuthScreenState extends State<CustomerAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login fields
  final _loginEmailCtrl    = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  bool _loginPasswordVisible = false;
  bool _loginLoading = false;
  String? _loginError;

  // Register fields
  final _regNameCtrl     = TextEditingController();
  final _regEmailCtrl    = TextEditingController();
  final _regPhoneCtrl    = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regConfirmCtrl  = TextEditingController();
  bool _regPasswordVisible = false;
  bool _regLoading = false;
  String? _regError;

  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey   = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, vsync: this,
      initialIndex: widget.startOnRegister ? 1 : 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() { _loginLoading = true; _loginError = null; });

    try {
      // TODO: Connect to customer auth backend when ready
      await Future.delayed(const Duration(seconds: 1)); // simulate API
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Logged in successfully! 🎉'),
        backgroundColor: Colors.green.shade700));
      Navigator.pop(context);
    } catch (e) {
      setState(() => _loginError = 'Invalid email or password.');
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_regFormKey.currentState!.validate()) return;
    setState(() { _regLoading = true; _regError = null; });

    try {
      // TODO: Connect to customer auth backend when ready
      await Future.delayed(const Duration(seconds: 1)); // simulate API
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Account created! Please log in. 🎉'),
        backgroundColor: Colors.green.shade700));
      _tabController.animateTo(0);
    } catch (e) {
      setState(() => _regError = 'Registration failed. Try again.');
    } finally {
      if (mounted) setState(() => _regLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Account',
          style: GoogleFonts.dmSans(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(children: [
            // Logo area
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                RichText(text: TextSpan(children: [
                  TextSpan(text: 'Kachipapa',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
                  TextSpan(text: 'Store',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26, fontWeight: FontWeight.w700,
                      color: AppTheme.primaryRed)),
                ])),
                const SizedBox(height: 4),
                Text('Malawi\'s Premier Online Marketplace',
                  style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppTheme.textHint)),
              ]),
            ),

            // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryRed,
                unselectedLabelColor: AppTheme.textHint,
                indicatorColor: AppTheme.primaryRed,
                labelStyle: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [
                  Tab(text: 'Sign In'),
                  Tab(text: 'Create Account'),
                ],
              ),
            ),

            // Tab views
            Expanded(child: TabBarView(
              controller: _tabController,
              children: [_loginTab(), _registerTab()],
            )),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOGIN TAB
  // ═══════════════════════════════════════════════════════════════
  Widget _loginTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: _loginFormKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Text('Welcome back! 👋',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text('Sign in to your account to continue shopping',
          style: GoogleFonts.dmSans(
            fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),

        // Email
        _label('Email Address'),
        TextFormField(
          controller: _loginEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDec('you@example.com', Icons.email_outlined),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter your email';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Password
        _label('Password'),
        TextFormField(
          controller: _loginPasswordCtrl,
          obscureText: !_loginPasswordVisible,
          decoration: _inputDec('••••••••', Icons.lock_outlined,
            suffix: IconButton(
              icon: Icon(_loginPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
                size: 20, color: AppTheme.textHint),
              onPressed: () => setState(
                  () => _loginPasswordVisible = !_loginPasswordVisible))),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter your password';
            return null;
          },
        ),

        // Forgot password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text('Forgot password?',
              style: GoogleFonts.dmSans(
                color: AppTheme.primaryRed, fontSize: 12)),
          ),
        ),

        // Error
        if (_loginError != null) _errorBox(_loginError!),
        const SizedBox(height: 8),

        // Login button
        SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _loginLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
            child: _loginLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text('Sign In',
                    style: GoogleFonts.dmSans(
                        color: Colors.white, fontWeight: FontWeight.w700,
                        fontSize: 15)),
          ),
        ),
        const SizedBox(height: 16),

        // Divider
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('or', style: GoogleFonts.dmSans(
                color: AppTheme.textHint, fontSize: 12))),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 16),

        // Switch to register
        Center(child: TextButton(
          onPressed: () => _tabController.animateTo(1),
          child: Text("Don't have an account? Create one",
            style: GoogleFonts.dmSans(
              color: AppTheme.primaryRed, fontWeight: FontWeight.w600,
              fontSize: 13)),
        )),
      ]),
    ),
  );

  // ═══════════════════════════════════════════════════════════════
  //  REGISTER TAB
  // ═══════════════════════════════════════════════════════════════
  Widget _registerTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: _regFormKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Text('Create your account 🎉',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text('Join thousands of shoppers in Malawi',
          style: GoogleFonts.dmSans(
            fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),

        // Full name
        _label('Full Name'),
        TextFormField(
          controller: _regNameCtrl,
          decoration: _inputDec('e.g. Chisomo Banda', Icons.person_outlined),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter your name';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Email
        _label('Email Address'),
        TextFormField(
          controller: _regEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDec('you@example.com', Icons.email_outlined),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter your email';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Phone
        _label('Phone Number'),
        TextFormField(
          controller: _regPhoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: _inputDec('e.g. 0881234567', Icons.phone_outlined),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter your phone number';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Password
        _label('Password'),
        TextFormField(
          controller: _regPasswordCtrl,
          obscureText: !_regPasswordVisible,
          decoration: _inputDec('••••••••', Icons.lock_outlined,
            suffix: IconButton(
              icon: Icon(_regPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
                size: 20, color: AppTheme.textHint),
              onPressed: () => setState(
                  () => _regPasswordVisible = !_regPasswordVisible))),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter a password';
            if (v.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Confirm password
        _label('Confirm Password'),
        TextFormField(
          controller: _regConfirmCtrl,
          obscureText: true,
          decoration: _inputDec('••••••••', Icons.lock_outlined),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != _regPasswordCtrl.text) return 'Passwords do not match';
            return null;
          },
        ),

        // Error
        if (_regError != null) ...[
          const SizedBox(height: 12),
          _errorBox(_regError!),
        ],
        const SizedBox(height: 24),

        // Register button
        SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _regLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
            child: _regLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text('Create Account',
                    style: GoogleFonts.dmSans(
                        color: Colors.white, fontWeight: FontWeight.w700,
                        fontSize: 15)),
          ),
        ),
        const SizedBox(height: 16),

        Center(child: TextButton(
          onPressed: () => _tabController.animateTo(0),
          child: Text('Already have an account? Sign in',
            style: GoogleFonts.dmSans(
              color: AppTheme.primaryRed, fontWeight: FontWeight.w600,
              fontSize: 13)),
        )),
        const SizedBox(height: 16),

        // Terms
        Center(child: Text(
          'By creating an account you agree to our\nTerms of Service and Privacy Policy',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
              fontSize: 11, color: AppTheme.textHint),
        )),
      ]),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
      style: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary, letterSpacing: 0.3)),
  );

  InputDecoration _inputDec(String hint, IconData icon, {Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textHint),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF4F4F2),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: AppTheme.primaryRed, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppTheme.primaryRed.withOpacity(0.5))),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: AppTheme.primaryRed, width: 1.5)),
    );

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0F2),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppTheme.primaryRed, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
        style: GoogleFonts.dmSans(
            color: AppTheme.primaryRed, fontSize: 13,
            fontWeight: FontWeight.w500))),
    ]),
  );
}
