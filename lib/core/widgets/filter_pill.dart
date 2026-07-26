import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A date-filter pill with a gradient fill and a light spring-in bounce
/// when selected, replacing the flat default ChoiceChip look. Shared by
/// the dashboard and the full transactions screen so both filter bars
/// stay visually identical.
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.0 : 0.96,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.chipSelected : null,
            color: selected ? null : AppColors.plumElevated,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: selected ? Colors.transparent : AppColors.offWhiteDim(0.08)),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.mauveDim(0.35), blurRadius: 14, offset: const Offset(0, 4))]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.black : AppColors.offWhiteDim(0.7),
            ),
          ),
        ),
      ),
    );
  }
}
