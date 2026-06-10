import 'package:flutter/material.dart';

abstract final class AppDialogs {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final actionColor = destructive ? colors.error : colors.primary;

        return AlertDialog(
          backgroundColor: theme.cardColor,
          surfaceTintColor: Colors.transparent,
          elevation: 12,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.outline),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.72),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor:
                    destructive ? colors.onError : colors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
