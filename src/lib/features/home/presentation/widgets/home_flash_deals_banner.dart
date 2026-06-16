// =============================================================
// FILE: lib/features/home/presentation/widgets/home_flash_deals_banner.dart
//
// PURPOSE:
//   The red flash sale banner with a live countdown timer.
//
//   WHAT YOU LEARN HERE:
//   - Receiving state values as parameters (hours, minutes, seconds)
//   - Why the TIMER lives in the PARENT screen, not here
//
//   IMPORTANT DESIGN DECISION — why is the timer in the parent?
//   This widget only DISPLAYS the countdown. It doesn't own the
//   timer logic. The parent (HomeScreen) owns the Timer object
//   and calls setState() every second, passing the new values
//   down here as parameters.
//
//   WHY NOT PUT THE TIMER HERE?
//   If the timer lived here, when Flutter rebuilds this widget
//   (e.g. user scrolls), a new timer would start. By keeping
//   the timer in the parent's initState/dispose, it runs once
//   for the lifetime of the screen — clean and safe.
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

class HomeFlashDealsBanner extends StatelessWidget {
  // These are passed in from the parent every second
  // as the countdown ticks — that's what triggers the rebuild
  final int hours;
  final int minutes;
  final int seconds;

  const HomeFlashDealsBanner({
    super.key,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC8102E), Color(0xFFE63950)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Lightning emoji
          const Text('⚡', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Flash Sale — Up to 60% Off",
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Limited stock · Ends at midnight',
                  style: GoogleFonts.dmSans(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Countdown boxes
          Row(
            children: [
              _CountdownBox(value: hours,   label: 'HRS'),
              const SizedBox(width: 6),
              _CountdownBox(value: minutes, label: 'MIN'),
              const SizedBox(width: 6),
              _CountdownBox(value: seconds, label: 'SEC'),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------
// PRIVATE WIDGET — _CountdownBox
// Displays a single time unit box (e.g. "04 HRS").
// Private because only HomeFlashDealsBanner uses it.
// ----------------------------------------------------------
class _CountdownBox extends StatelessWidget {
  final int    value;
  final String label;

  const _CountdownBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        children: [
          Text(
            // padLeft(2, '0') turns "4" into "04"
            value.toString().padLeft(2, '0'),
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              // tabularFigures prevents digits from jumping width
              // as the number changes each second
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white70,
              fontSize: 8,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
