import 'package:flutter/material.dart';

enum _NotificationType { success, error, warning, info }

abstract final class AppNotifier {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      type: _NotificationType.success,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      type: _NotificationType.error,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      type: _NotificationType.warning,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      type: _NotificationType.info,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required _NotificationType type,
    required Duration duration,
  }) {
    final currentMessenger = messengerKey.currentState;
    final messenger = currentMessenger != null && currentMessenger.mounted
        ? currentMessenger
        : ScaffoldMessenger.maybeOf(context);

    if (messenger == null) return;

    final style = _styleFor(type);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: style.background,
          elevation: 8,
          duration: duration,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
  }

  static ({Color background, IconData icon}) _styleFor(
    _NotificationType type,
  ) {
    switch (type) {
      case _NotificationType.success:
        return (
          background: const Color(0xFF10B981),
          icon: Icons.check_circle_outline,
        );
      case _NotificationType.error:
        return (
          background: const Color(0xFFEF4444),
          icon: Icons.error_outline,
        );
      case _NotificationType.warning:
        return (
          background: const Color(0xFFF59E0B),
          icon: Icons.warning_amber_rounded,
        );
      case _NotificationType.info:
        return (
          background: const Color(0xFF06B6D4),
          icon: Icons.info_outline,
        );
    }
  }
}
