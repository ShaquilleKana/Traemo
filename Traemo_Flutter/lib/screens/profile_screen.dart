import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_messages.dart';
import '../core/widgets/app_dialogs.dart';
import '../core/widgets/app_notifier.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_switch.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onLogout,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String _userName = 'John Doe';
  String _userEmail = 'john.doe@example.com';
  bool isReminderEnabled = true;
  TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadReminderSettings();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name');
    final userEmail = prefs.getString('user_email');

    if (!mounted) return;

    setState(() {
      _userName =
          (userName != null && userName.isNotEmpty) ? userName : _userName;
      _userEmail =
          (userEmail != null && userEmail.isNotEmpty) ? userEmail : _userEmail;
    });
  }

  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('reminder_enabled') ?? true;
    final savedTime = prefs.getString('reminder_time') ?? '20:00';
    final time = _parseReminderTime(savedTime);

    await prefs.setBool('reminder_enabled', enabled);
    await prefs.setString('reminder_time', _formatReminderTime(time));

    if (enabled) {
      await NotificationService.scheduleDailyReminder(
        hour: time.hour,
        minute: time.minute,
      );
    }

    if (!mounted) return;

    setState(() {
      isReminderEnabled = enabled;
      reminderTime = time;
    });
  }

  Future<void> _setReminderEnabled(bool enabled) async {
    setState(() => isReminderEnabled = enabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', enabled);
    await prefs.setString('reminder_time', _formatReminderTime(reminderTime));

    if (enabled) {
      await NotificationService.scheduleDailyReminder(
        hour: reminderTime.hour,
        minute: reminderTime.minute,
      );
      if (!mounted) return;
      AppNotifier.showInfo(
        context,
        message:
            '${AppMessages.reminderEnabled} ${_formatReminderTime(reminderTime)}',
      );
    } else {
      await NotificationService.cancelReminder();
      if (!mounted) return;
      AppNotifier.showInfo(
        context,
        message: AppMessages.reminderDisabled,
      );
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) return;

    setState(() => reminderTime = picked);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminder_time', _formatReminderTime(picked));
    await NotificationService.scheduleDailyReminder(
      hour: picked.hour,
      minute: picked.minute,
    );
    if (!mounted) return;
    AppNotifier.showInfo(
      context,
      message: '${AppMessages.reminderEnabled} ${_formatReminderTime(picked)}',
    );
  }

  TimeOfDay _parseReminderTime(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return const TimeOfDay(hour: 20, minute: 0);
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatReminderTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _exportTransactions() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw const ApiException('Sesi login berakhir. Silakan login ulang.');
      }

      final filePath = await ApiService.exportTransactionsToExcel(token);

      if (!mounted) return;
      developer.log('EXPORTED TRANSACTIONS TO: $filePath',
          name: 'ProfileScreen');
      AppNotifier.showSuccess(
        context,
        message: AppMessages.exportSuccess,
      );
    } catch (e) {
      if (!mounted) return;
      final message = _buildExportErrorMessage(e);
      if (message == AppMessages.noDataToExport) {
        AppNotifier.showWarning(
          context,
          message: message,
        );
      } else {
        AppNotifier.showError(
          context,
          message: message,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _buildExportErrorMessage(Object error) {
    if (error is ApiException && error.message.isNotEmpty) {
      final normalized = error.message.toLowerCase();
      if (normalized.contains('belum') ||
          normalized.contains('tidak ada') ||
          normalized.contains('no data')) {
        return AppMessages.noDataToExport;
      }
      if (normalized.contains('server')) {
        return AppMessages.serverError;
      }
    }

    return AppMessages.exportFailed;
  }

  Future<void> _confirmLogout() async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppMessages.logoutDialogTitle,
      message: AppMessages.logoutDialogMessage,
      cancelLabel: AppMessages.cancel,
      confirmLabel: AppMessages.logout,
      destructive: true,
    );

    if (!confirmed || !mounted) return;
    await widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final fg =
        widget.isDark ? AppColors.darkForeground : AppColors.lightForeground;
    final muted = widget.isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final card = widget.isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primary =
        widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final onPrimary = widget.isDark
        ? AppColors.darkPrimaryForeground
        : AppColors.lightPrimaryForeground;
    final secondary =
        widget.isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final destructive =
        widget.isDark ? AppColors.darkDestructive : AppColors.lightDestructive;
    final onDestructive = widget.isDark
        ? AppColors.darkDestructiveForeground
        : AppColors.lightDestructiveForeground;

    final menuItems = <({IconData icon, String label})>[
      (icon: Icons.settings_outlined, label: 'Settings'),
      (icon: Icons.notifications_outlined, label: 'Notifications'),
      (icon: Icons.lock_outline, label: 'Privacy & Security'),
      (icon: Icons.file_download_outlined, label: 'Export to Excel'),
    ];

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your account',
            style: TextStyle(fontSize: 14, color: muted),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.05),
                  primary.withValues(alpha: 0.10),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(Icons.person, size: 48, color: onPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline, size: 16, color: muted),
                    const SizedBox(width: 8),
                    Text(
                      _userEmail,
                      style: TextStyle(fontSize: 14, color: muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    size: 20,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dark Mode',
                        style:
                            TextStyle(fontWeight: FontWeight.w500, color: fg),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isDark ? 'Enabled' : 'Disabled',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
                AppSwitch(
                  value: widget.isDark,
                  onChanged: (_) => widget.onToggleTheme(),
                  isDark: widget.isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        size: 20,
                        color: fg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reminder Pencatatan',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: fg,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bantu kamu tetap konsisten mencatat transaksi harian',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppSwitch(
                      value: isReminderEnabled,
                      onChanged: _setReminderEnabled,
                      isDark: widget.isDark,
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: isReminderEnabled
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _pickReminderTime,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: secondary,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_outlined,
                                      size: 20,
                                      color: primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Waktu Reminder',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: muted,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatReminderTime(reminderTime),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: fg,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit_calendar_outlined,
                                      size: 20,
                                      color: muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final item in menuItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: item.label == 'Export to Excel' && !_isExporting
                      ? _exportTransactions
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: item.label == 'Export to Excel' && _isExporting
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(fg),
                                  ),
                                )
                              : Icon(item.icon, size: 20, color: fg),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                                fontWeight: FontWeight.w500, color: fg),
                          ),
                        ),
                        Icon(Icons.arrow_forward, size: 20, color: muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _confirmLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isDark
                    ? destructive.withValues(alpha: 0.6)
                    : destructive,
                foregroundColor: onDestructive,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: onDestructive,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Traemo v1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
  }
}
