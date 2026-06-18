import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

/// Circular hook score badge used on analysis result and history cards.
class ScoreBadge extends StatelessWidget {
  final int score;
  final double size;

  const ScoreBadge({super.key, required this.score, this.size = 56});

  Color get _color {
    if (score >= 7) return AppTheme.successColor;
    if (score >= 4) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withOpacity(0.12),
        border: Border.all(color: _color.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: Text(
          '$score',
          style: GoogleFonts.outfit(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: _color,
          ),
        ),
      ),
    );
  }
}
