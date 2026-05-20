import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _typing = false;
  static const _initialGreeting = 'Halo 👋\nSilakan catat transaksi kamu.';

  static const _quickActions = <({String label, String value})>[
    (label: 'makan 10k', value: 'makan 10000'),
    (label: 'bensin 20k', value: 'bensin 20000'),
    (label: 'gaji 1jt', value: 'gaji 1000000'),
  ];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");

      if (userId == null) return;

      final chats = await ApiService.getChats(userId);

      if (!mounted) return;

      setState(() {
        _messages
          ..clear()
          ..addAll(
            chats.isEmpty
                ? [
                    {
                      "text": _initialGreeting,
                      "sender": "bot",
                    }
                  ]
                : chats.map<Map<String, String>>((chat) {
                    return {
                      "text": chat["message"].toString(),
                      "sender": chat["sender"].toString(),
                    };
                  }).toList(),
          );
      });
      _scrollToBottom();
    } catch (e) {
      developer.log("LOAD CHAT ERROR: $e", name: 'ChatScreen');
    }
  }

  Future<void> _handleSend([String? text]) async {
    final messageText = text ?? _input.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _messages.add({
        'text': messageText,
        'sender': 'user',
      });
      _input.clear();
      _typing = true;
    });
    _scrollToBottom();

    String botResponse = 'Terjadi kesalahan koneksi';

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");
      if (userId == null) {
        throw Exception("User session not found");
      }

      final response = await ApiService.sendMessage(messageText, userId);
      final responseMessage = response['message'];
      if (responseMessage is String && responseMessage.trim().isNotEmpty) {
        botResponse = responseMessage;
      }
    } catch (_) {
      botResponse = 'Terjadi kesalahan koneksi';
    }

    if (!mounted) return;

    setState(() {
      _messages.add({
        'text': botResponse,
        'sender': 'bot',
      });
      _typing = false;
    });
    _scrollToBottom();
  }

  Future<void> _confirmClearChats() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat Chat'),
        content: const Text(
          'Yakin ingin menghapus seluruh riwayat chat?\n\nData transaksi tetap aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");
      if (userId == null) {
        throw Exception("User session not found");
      }

      await ApiService.clearChats(userId);

      if (!mounted) return;

      setState(() {
        _typing = false;
        _messages
          ..clear()
          ..add({
            'text': _initialGreeting,
            'sender': 'bot',
          });
      });
      _scrollToBottom();
    } catch (e) {
      developer.log("CLEAR CHAT ERROR: $e", name: 'ChatScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fg = isDark ? AppColors.darkForeground : AppColors.lightForeground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final onPrimary = isDark
        ? AppColors.darkPrimaryForeground
        : AppColors.lightPrimaryForeground;
    final secondary =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final secondaryFg = isDark
        ? AppColors.darkSecondaryForeground
        : AppColors.lightSecondaryForeground;
    final inputBg =
        isDark ? AppColors.darkInputBackground : AppColors.lightInputBackground;

    return ColoredBox(
      color: bg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: card,
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Traemo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your financial assistant',
                      style: TextStyle(fontSize: 14, color: muted),
                    ),
                  ],
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _confirmClearChats,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: primary,
                    ),
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: _messages.length + (_typing ? 1 : 0) + 1,
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  final m = _messages[index];
                  final isUser = m['sender'] == 'user';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection:
                                isUser ? TextDirection.rtl : TextDirection.ltr,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isUser ? primary : secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isUser
                                      ? Icons.person
                                      : Icons.smart_toy_outlined,
                                  size: 16,
                                  color: isUser ? onPrimary : primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser ? primary : card,
                                    border: isUser
                                        ? null
                                        : Border.all(color: border),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(isUser ? 16 : 4),
                                      topRight:
                                          Radius.circular(isUser ? 4 : 16),
                                      bottomLeft: const Radius.circular(16),
                                      bottomRight: const Radius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    m['text'] ?? '',
                                    textAlign: TextAlign.start,
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.45,
                                      color: isUser ? onPrimary : fg,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (_typing) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.smart_toy_outlined,
                                  size: 16,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: card,
                                  border: Border.all(color: border),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: const _TypingDots(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: card,
              border: Border(top: BorderSide(color: border)),
            ),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final a in _quickActions) ...[
                        Material(
                          color: secondary,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            onTap: () {
                              _input.text = a.value;
                              _input.selection = TextSelection.fromPosition(
                                TextPosition(offset: _input.text.length),
                              );
                            },
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                a.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: secondaryFg,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _input,
                          onSubmitted: (_) => _handleSend(),
                          decoration: InputDecoration(
                            hintText: 'Type a transaction...',
                            hintStyle: TextStyle(color: muted),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: border),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _handleSend(),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: primary,
                          foregroundColor: onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Icon(Icons.send, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor =
        isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        double op(int delaySteps) {
          final t = (_controller.value + delaySteps * 0.2) % 1.0;
          final wave = (t < 0.5) ? t * 2 : 2 - t * 2;
          return 0.4 + 0.6 * wave;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: op(0),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Opacity(
              opacity: op(1),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Opacity(
              opacity: op(2),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
