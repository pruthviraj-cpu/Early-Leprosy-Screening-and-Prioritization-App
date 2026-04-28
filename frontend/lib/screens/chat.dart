import 'package:flutter/material.dart';
import '../features/chat/model/chat_message.dart';
import '../services/cache_service.dart';
import '../services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

const _white        = Color(0xFFFFFFFF);
const _bgPage       = Color(0xFFF0F4F9); 
const _surfaceCard  = Color(0xFFFFFFFF);
const _userBubble   = Color(0xFFE8F0FE); 
const _userText     = Color(0xFF1F1F1F);
const _aiText       = Color(0xFF1F1F1F);
const _hintText     = Color(0xFF9AA0A6);
const _iconGrey     = Color(0xFF5F6368);
const _divider      = Color(0xFFE8EAED);
const _accentBlue   = Color(0xFF1A73E8); 
const _pendingAmber = Color(0xFFF9AB00);
const _errorRed     = Color(0xFFD93025);
const _successGreen = Color(0xFF188038);
const _offlineBg    = Color(0xFFFEF7E0);
const _offlineText  = Color(0xFF7D5700);


const _geminiBlue   = Color(0xFF4285F4);
const _geminiRed    = Color(0xFF1A73E8); 
const _geminiYellow = Color(0xFF1A73E8); 
const _geminiGreen  = Color(0xFF34A853);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> chats = [];
  late final StreamSubscription<ConnectivityResult> _connectivitySub;
  bool _isSyncing = false;
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;

  // ── Animation for new messages ─────────────────────────────────────────────
  final Map<String, AnimationController> _messageControllers = {};

  @override
  void initState() {
    super.initState();
    loadChats();
    listenToInternet();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  AnimationController _getController(String id) {
    if (!_messageControllers.containsKey(id)) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 280),
      )..forward();
      _messageControllers[id] = ctrl;
    }
    return _messageControllers[id]!;
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ── ALL LOGIC BELOW IS UNTOUCHED ─────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════════

  void listenToInternet() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) syncPendingMessages();
    });
  }

  void loadChats() {
    final cachedChats = CacheService.getAllMessages();
    cachedChats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    setState(() => chats = cachedChats);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> syncPendingMessages() async {
    if (_isSyncing) return;
    _isSyncing = true;
    setState(() {});
    try {
      final messages = CacheService.getAllMessages();
      final pendingMessages = messages
          .where((m) => m.role == 'user' && m.syncStatus == 'pending')
          .toList();
      if (pendingMessages.isEmpty) {
        _isSyncing = false;
        setState(() {});
        return;
      }
      for (final msg in pendingMessages) {
        try {
          msg.syncStatus = 'sending';
          await msg.save();
          final reply = await ApiService.sendChat(msg.message);
          msg.syncStatus = 'synced';
          await msg.save();
          final aiMessage = ChatMessage(
            id: '${msg.id}_reply_${DateTime.now().millisecondsSinceEpoch}',
            role: 'ai',
            message: reply,
            createdAt: DateTime.now(),
            syncStatus: 'synced',
          );
          await CacheService.saveMessage(aiMessage);
          if (mounted) {
            setState(() {
              chats.add(aiMessage);
              chats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            });
            _scrollToBottom();
          }
        } catch (e) {
          debugPrint('Failed to sync message: $e');
          msg.syncStatus = 'pending';
          await msg.save();
        }
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final userMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_user',
      role: 'user',
      message: _controller.text.trim(),
      createdAt: DateTime.now(),
      syncStatus: 'pending',
    );
    _controller.clear();
    await CacheService.saveMessage(userMessage);
    setState(() {
      chats.add(userMessage);
      chats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
    _scrollToBottom();
    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet = connectivity != ConnectivityResult.none;
    if (hasInternet) {
      await _sendToBackend(userMessage);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(
          icon: Icons.wifi_off_rounded,
          message: 'Message saved. Will send when connected.',
          color: _pendingAmber,
        ),
      );
    }
  }

  Future<void> _sendToBackend(ChatMessage userMessage) async {
    try {
      userMessage.syncStatus = 'sending';
      await userMessage.save();
      final aiReply = await ApiService.sendChat(userMessage.message);
      userMessage.syncStatus = 'synced';
      await userMessage.save();
      final aiMessage = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        role: 'ai',
        message: aiReply,
        createdAt: DateTime.now(),
        syncStatus: 'synced',
      );
      await CacheService.saveMessage(aiMessage);
      if (mounted) {
        setState(() {
          chats.add(aiMessage);
          chats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Backend send error: $e');
      userMessage.syncStatus = 'failed';
      await userMessage.save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar(
            icon: Icons.error_outline_rounded,
            message: 'Failed to send. Will retry when online.',
            color: _errorRed,
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ── UI HELPERS ────────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════════

  SnackBar _buildSnackBar({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: color,
      elevation: 4,
      content: Row(
        children: [
          Icon(icon, color: _white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _connectivitySub.cancel();
    _scrollController.dispose();
    for (final c in _messageControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ── BUILD ─────────────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildOfflineBanner(),
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _bgPage,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GeminiSparkleIcon(size: 22),
          const SizedBox(width: 10),
          const Text(
            'AI Assistant',
            style: TextStyle(
              color: _userText,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _isSyncing
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_accentBlue),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.sync_rounded, color: _iconGrey, size: 22),
                  onPressed: syncPendingMessages,
                  tooltip: 'Sync messages',
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                  ),
                ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: _divider),
      ),
    );
  }

  // ── Offline Banner ────────────────────────────────────────────────────────────
  Widget _buildOfflineBanner() {
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged,
      initialData: ConnectivityResult.none,
      builder: (context, snapshot) {
        final isConnected = snapshot.data != ConnectivityResult.none;
        if (isConnected) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _offlineBg,
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, size: 15, color: _offlineText),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'You\'re offline — messages will send when reconnected',
                  style: TextStyle(
                    color: _offlineText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Message List ──────────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    if (chats.isEmpty) return _buildEmptyState();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        final ctrl = _getController(chat.id);
        return FadeTransition(
          opacity: CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut)),
            child: chat.role == 'user'
                ? _buildUserMessage(chat)
                : _buildAiMessage(chat),
          ),
        );
      },
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GeminiSparkleIcon(size: 52),
            const SizedBox(height: 28),
            const Text(
              'Hello there',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w300,
                color: _userText,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'How can I help you today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: _iconGrey,
                height: 1.4,
              ),
            ),

          ],
        ),
      ),
    );
  }

  // ── User Message Bubble ───────────────────────────────────────────────────────
  Widget _buildUserMessage(ChatMessage chat) {
    Widget? statusIcon;
    switch (chat.syncStatus) {
      case 'pending':
        statusIcon = Icon(Icons.schedule_rounded, size: 12, color: _pendingAmber);
        break;
      case 'sending':
        statusIcon = SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(_accentBlue),
          ),
        );
        break;
      case 'failed':
        statusIcon = Icon(Icons.error_outline_rounded, size: 12, color: _errorRed);
        break;
      case 'synced':
        statusIcon = Icon(Icons.done_all_rounded, size: 12, color: _successGreen);
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: _userBubble,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    chat.message,
                    style: const TextStyle(
                      color: _userText,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(chat.createdAt),
                        style: const TextStyle(
                          color: _iconGrey,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (statusIcon != null) ...[
                        const SizedBox(width: 5),
                        statusIcon,
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AI Message (no bubble, just icon + text) ──────────────────
  Widget _buildAiMessage(ChatMessage chat) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 12),
            child: _GeminiSparkleIcon(size: 20),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.message,
                  style: const TextStyle(
                    color: _aiText,
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(chat.createdAt),
                  style: const TextStyle(
                    color: _hintText,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Bar ─────────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = bottomInset > 0 ? 10.0 : MediaQuery.of(context).padding.bottom + 10;
    return Container(
      color: _bgPage,
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceCard,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: _divider, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _userText,
                    height: 1.45,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(
                      color: _hintText,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
            ),

            // Send / mic button
            Padding(
              padding: const EdgeInsets.all(6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: _hasText
                    ? _SendButton(key: const ValueKey('send'), onTap: sendMessage)
                    : _MicButton(key: const ValueKey('mic')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:$m $period';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Sub-Widgets ───────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _GeminiSparkleIcon extends StatelessWidget {
  final double size;
  const _GeminiSparkleIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [_geminiBlue, _geminiRed, _geminiYellow, _geminiGreen],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Icon(Icons.auto_awesome_rounded, size: size, color: Colors.white),
    );
  }
}

/// Animated send button
class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: _accentBlue,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_upward_rounded, color: _white, size: 20),
      ),
    );
  }
}

/// Mic button (when input is empty)
class _MicButton extends StatelessWidget {
  const _MicButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _bgPage,
        shape: BoxShape.circle,
        border: Border.all(color: _divider, width: 1),
      ),
      child: const Icon(Icons.mic_none_rounded, color: _iconGrey, size: 20),
    );
  }
}