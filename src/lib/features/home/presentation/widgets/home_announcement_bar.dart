// =============================================================
// FILE: lib/features/home/presentation/widgets/home_announcement_bar.dart
//
// PURPOSE:
//   The thin red bar at the very top of the homepage showing
//   delivery info and payment methods.
//
//   WHY A SEPARATE WIDGET?
//   This bar might appear on multiple screens (home, category,
//   product detail). By extracting it here, we reuse it
//   everywhere without copy-pasting code.
//
//   STATELESSWIDGET — no state needed here.
//   This widget just displays static text. It never changes.
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

class HomeAnnouncementBar extends StatelessWidget {
  // We could make the message a parameter if we want to
  // customize it per screen — for now it's hardcoded.
  const HomeAnnouncementBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryRed,
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Center(
        child: Text(
          '🚚 Free delivery on orders over MK 5,000  ·  Airtel Money & TNM Mpamba',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
