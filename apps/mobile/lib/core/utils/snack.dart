import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Red snack bar used to report a failure.
///
/// Callers are responsible for checking that [context] is still mounted.
void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppColors.danger),
  );
}

/// Green snack bar used to confirm a completed action.
///
/// Callers are responsible for checking that [context] is still mounted.
void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppColors.success),
  );
}
