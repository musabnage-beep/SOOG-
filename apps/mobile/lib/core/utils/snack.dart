import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Red snack bar used to report a failure.
///
/// Callers are responsible for checking that [context] is still mounted.
void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: _onFill),
      backgroundColor: AppColors.danger,
    ),
  );
}

/// Green snack bar used to confirm a completed action.
///
/// Callers are responsible for checking that [context] is still mounted.
void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: _onFill),
      backgroundColor: AppColors.success,
    ),
  );
}

/// Both bars replace the themed background with a saturated fill, so they have
/// to replace its ink too: the themed colour is page ink, which is unreadable
/// on red or green.
const _onFill = TextStyle(color: AppColors.white, fontWeight: FontWeight.w600);
