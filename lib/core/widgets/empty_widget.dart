import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';

class EmptyWidget extends StatelessWidget {
  final String? message;
  final IconData? icon;
  
  const EmptyWidget({
    super.key,
    this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.inbox_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? AppStrings.empty,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

