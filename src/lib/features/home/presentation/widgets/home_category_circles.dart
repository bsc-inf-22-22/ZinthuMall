// =============================================================
// FILE: lib/features/home/presentation/widgets/home_category_circles.dart
//
// PURPOSE:
//   A horizontal scrollable row of category icon circles.
//   When the user taps one, it highlights and the parent
//   screen navigates to that category.
//
//   WHAT YOU LEARN HERE:
//   - StatefulWidget for local UI state (selected index)
//   - SingleChildScrollView for horizontal scrolling
//   - AnimatedContainer for smooth selection animation
//   - Passing data DOWN via constructor parameters
//   - Passing events UP via callbacks (onCategorySelected)
//
//   PARENT ↔ CHILD COMMUNICATION PATTERN:
//   Data flows DOWN:  parent gives categories list to this widget
//   Events flow UP:   this widget calls onCategorySelected(index)
//                     and the parent decides what to do with it
//   This is called "lifting state up" — a core Flutter pattern.
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

// ----------------------------------------------------------
// CATEGORY MODEL
// A simple data class to hold one category's display data.
// Using a class instead of a Map gives us type safety and
// auto-complete in the editor.
// ----------------------------------------------------------
class CategoryItem {
  final String label;
  final String emoji;
  final Color  color;
  final String key; // matches the backend category string

  const CategoryItem({
    required this.label,
    required this.emoji,
    required this.color,
    required this.key,
  });
}

class HomeCategoryCircles extends StatefulWidget {
  // The list of categories to display — passed from parent
  final List<CategoryItem> categories;

  // Called when user taps a category circle.
  // Passes back the CategoryItem so the parent knows which one.
  final void Function(CategoryItem category) onCategorySelected;

  const HomeCategoryCircles({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  State<HomeCategoryCircles> createState() => _HomeCategoryCirclesState();
}

class _HomeCategoryCirclesState extends State<HomeCategoryCircles> {
  // Which circle is currently highlighted
  // This is LOCAL state — only this widget cares about it
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // scrollDirection: Axis.horizontal makes this scroll sideways
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
      child: Row(
        // widget.categories accesses the parent-provided list
        children: List.generate(widget.categories.length, (index) {
          return _buildCircle(index);
        }),
      ),
    );
  }

  Widget _buildCircle(int index) {
    final category   = widget.categories[index];
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        // 1. Update LOCAL state to highlight this circle
        setState(() => _selectedIndex = index);

        // 2. Notify the PARENT which category was tapped
        //    The parent decides what to do (navigate, filter, etc.)
        widget.onCategorySelected(category);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            // --------------------------------------------------
            // AnimatedContainer smoothly transitions its
            // decoration when isSelected changes.
            // Without it, the border would snap on instantly.
            // duration controls how long the animation takes.
            // --------------------------------------------------
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryRed
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryRed.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Category label below the circle
            SizedBox(
              width: 72,
              child: Text(
                category.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppTheme.primaryRed
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
