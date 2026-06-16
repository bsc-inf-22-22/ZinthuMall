// =============================================================
// FILE: lib/features/home/presentation/widgets/home_hero_banner.dart
//
// PURPOSE:
//   The large promotional banner at the top of the homepage.
//   Contains:
//     - Left: dark gradient banner with CTA button
//     - Right: two smaller cards (Women's + Domestics)
//
//   WHAT YOU LEARN HERE:
//   - Passing callbacks (VoidCallback) as parameters
//     so the parent screen decides what happens on tap
//   - Using named parameters for clean, readable widget usage
//   - Gradient containers with LinearGradient
//   - Flexible layout with Expanded + flex values
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

class HomeHeroBanner extends StatelessWidget {
  // ----------------------------------------------------------
  // CALLBACKS — the parent screen passes these in.
  // The widget doesn't know WHERE to navigate —
  // that's the screen's job. The widget just says "I was tapped".
  //
  // VoidCallback = a function that takes no args, returns nothing
  // typedef VoidCallback = void Function();
  // ----------------------------------------------------------
  final VoidCallback onShopNowTap;
  final VoidCallback onWomensTap;
  final VoidCallback onDomesticsTap;

  const HomeHeroBanner({
    super.key,
    required this.onShopNowTap,
    required this.onWomensTap,
    required this.onDomesticsTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Row(
        children: [
          // Left: main large banner (takes 2/3 of width)
          Expanded(flex: 2, child: _buildMainBanner()),
          const SizedBox(width: 12),
          // Right: two stacked small cards (takes 1/3 of width)
          Expanded(flex: 1, child: _buildSideCards()),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // MAIN BANNER — dark gradient with headline + CTA
  // ----------------------------------------------------------
  Widget _buildMainBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF3D0012)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // "NEW COLLECTION 2025" tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              'NEW COLLECTION 2025',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Hero headline
          Text(
            'Dress Sharp.\nLive Bold.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Sub-headline
          Text(
            'Premium fashion delivered\nanywhere in Malawi',
            style: GoogleFonts.dmSans(
              color: Colors.white60,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Shop Now button — calls the callback passed from parent
          ElevatedButton.icon(
            onPressed: onShopNowTap,
            icon: const Icon(Icons.shopping_bag_outlined, size: 16),
            label: Text(
              'Shop Now',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SIDE CARDS — two small cards stacked vertically
  // ----------------------------------------------------------
  Widget _buildSideCards() {
    return Column(
      children: [
        Expanded(
          child: _HeroSideCard(
            label: "Women's Fashion",
            title: 'New Arrivals',
            emoji: '👗',
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF0F3), Color(0xFFFECDDB)],
            ),
            onTap: onWomensTap,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _HeroSideCard(
            label: 'Home & Kitchen',
            title: 'Domestics',
            emoji: '🏡',
            gradient: const LinearGradient(
              colors: [Color(0xFFEFF7FF), Color(0xFFC6E0FF)],
            ),
            onTap: onDomesticsTap,
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------
// PRIVATE WIDGET — _HeroSideCard
// The underscore means this widget is PRIVATE to this file.
// It's only used by HomeHeroBanner and nowhere else.
// This keeps our public API clean — only HomeHeroBanner is
// exported, not this internal detail.
// ----------------------------------------------------------
class _HeroSideCard extends StatelessWidget {
  final String   label;
  final String   title;
  final String   emoji;
  final Gradient gradient;
  final VoidCallback onTap;

  const _HeroSideCard({
    required this.label,
    required this.title,
    required this.emoji,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category label (small caps)
            Text(
              label.toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 4),
            // Card title
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            // Emoji
            Text(emoji, style: const TextStyle(fontSize: 28)),
            // CTA
            Row(
              children: [
                Text(
                  'Shop',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  size: 13,
                  color: AppTheme.primaryRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
