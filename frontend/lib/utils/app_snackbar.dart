import 'package:flutter/material.dart';

class AppSnackbar {
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xff10B981),
      icon: Icons.check_circle,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xffEF4444),
      icon: Icons.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xffF59E0B),
      icon: Icons.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xff3B82F6),
      icon: Icons.info,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
