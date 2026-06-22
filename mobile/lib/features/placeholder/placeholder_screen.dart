import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Temporary "coming soon" screen for tabs built in later phases.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 44, color: AppColors.faint),
            const SizedBox(height: 12),
            Text('Наскоро', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Овој дел е во изработка', style: TextStyle(color: AppColors.faint, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
