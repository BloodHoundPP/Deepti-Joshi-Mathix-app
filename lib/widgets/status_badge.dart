import 'package:flutter/material.dart';
import '../models/fee_model.dart';
import '../theme/app_colors.dart';

class FeeStatusBadge extends StatelessWidget {
  final FeeStatus status;

  const FeeStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case FeeStatus.paid:
        bg = AppColors.successLight;
        fg = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case FeeStatus.partial:
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        icon = Icons.timelapse_rounded;
        break;
      case FeeStatus.pending:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        icon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceBadge extends StatelessWidget {
  final bool isPresent;

  const AttendanceBadge({super.key, required this.isPresent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPresent ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 13,
            color: isPresent ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            isPresent ? 'Present' : 'Absent',
            style: TextStyle(
              color: isPresent ? AppColors.success : AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
