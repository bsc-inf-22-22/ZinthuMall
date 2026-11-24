// =============================================================
// FILE: lib/core/widgets/async_states.dart
//
// Shared loading / error / empty states so every screen behaves
// the same way when data is loading or the network fails.
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
      );
}

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textHint),
            const SizedBox(height: 12),
            Text(error.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 14)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: AppTheme.primaryRed),
                label: Text('Try again',
                    style: GoogleFonts.dmSans(color: AppTheme.primaryRed, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
        ),
      );
}

class EmptyView extends StatelessWidget {
  final String emoji;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    required this.emoji,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 14)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ]),
        ),
      );
}

/// Shown on account-only screens when nobody is signed in.
class SignInPrompt extends StatelessWidget {
  final String message;
  const SignInPrompt({super.key, required this.message});

  @override
  Widget build(BuildContext context) => EmptyView(
        emoji: '👤',
        title: 'Sign in to continue',
        message: message,
        actionLabel: 'Sign In',
        onAction: () => Navigator.pushNamed(context, '/login'),
      );
}
