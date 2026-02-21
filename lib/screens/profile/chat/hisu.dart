import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import '../../../widgets/custom_drawer.dart';
import '../../../config.dart';
import 'hisu_handler.dart';

// --- Hisu API Configuration ---
class HisuConfig {
  static String get apiUrl => '${AppConfig.animeApiBaseUrl}/hiotaku/api/v1/chat/';
  static const String authKey = String.fromEnvironment('hisu_authkey');
  static const String authKey2 = String.fromEnvironment('hisu_authkey2');
  static const String babeer = String.fromEnvironment('hisu_babeer');
  static const String apiKey = String.fromEnvironment('hisu_apikey');
}

// --- Main Entry Point ---
class HisuChatPage extends StatefulWidget {
  const HisuChatPage({super.key});

  @override
  State<HisuChatPage> createState() => _HisuChatPageState();
}

class _HisuChatPageState extends State<HisuChatPage> {
  final GlobalKey<CustomDrawerState> _drawerKey = GlobalKey<CustomDrawerState>();

  @override
  Widget build(BuildContext context) {
    return CustomDrawer(
      key: _drawerKey,
      drawerScreen: HisuDrawerScreen(
        onClose: () => _drawerKey.currentState?.toggle(),
      ),
      mainScreen: HisuChatScreen(
        onMenuPressed: () => _drawerKey.currentState?.toggle(),
      ),
    );
  }
}

// --- Data Models ---
enum SenderType { user, ai }

class ChatMessage {
  final String text;
  final SenderType sender;
  final List<AnimeCard> animeCards;

  const ChatMessage({
    required this.text,
    required this.sender,
    this.animeCards = const [],
  });
}

class AnimeCard {
  final String id;
  final String title;
  final String type;
  final String source;

  const AnimeCard({
    required this.id,
    required this.title,
    required this.type,
    required this.source,
  });

  factory AnimeCard.fromJson(Map<String, dynamic> json) {
    return AnimeCard(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      source: json['source'],
    );
  }
}

// --- Chat Screen ---
class HisuChatScreen extends StatefulWidget {
  final VoidCallback onMenuPressed;
  const HisuChatScreen({super.key, required this.onMenuPressed});

  @override
  State<HisuChatScreen> createState() => _HisuChatScreenState();
}

class _HisuChatScreenState extends State<HisuChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isAITyping = false;
  ChatMessage? _editingMessage;
  String? _selectedOptionText;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _saveChatHistory();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    final history = await HisuHandler.loadChatHistory();
    if (history.isNotEmpty) {
      setState(() {
        _messages.addAll(history.map((msg) => ChatMessage(
          text: msg['text'],
          sender: msg['sender'] == 'user' ? SenderType.user : SenderType.ai,
          animeCards: (msg['animeCards'] as List?)
              ?.map((card) => AnimeCard.fromJson(card))
              .toList() ?? [],
        )));
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveChatHistory() async {
    final history = _messages.map((msg) => {
      'text': msg.text,
      'sender': msg.sender == SenderType.user ? 'user' : 'ai',
      'animeCards': msg.animeCards.map((card) => {
        'id': card.id,
        'title': card.title,
        'type': card.type,
        'source': card.source,
      }).toList(),
    }).toList();
    await HisuHandler.saveChatHistory(history);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (_editingMessage != null) {
      final index = _messages.indexOf(_editingMessage!);
      if (index != -1) {
        setState(() {
          _messages[index] = ChatMessage(text: text, sender: _editingMessage!.sender);
          _editingMessage = null;
        });
        _saveChatHistory();
      }
    } else {
      setState(() {
        _messages.add(ChatMessage(text: text, sender: SenderType.user));
        _isAITyping = true;
      });
      _scrollToBottom();

      final result = await HisuHandler.sendMessage(text);

      if (result['success'] == true) {
        final animeCards = (result['anime_cards'] as List?)
            ?.map((card) => AnimeCard.fromJson(card))
            .toList() ?? [];

        setState(() {
          _messages.add(ChatMessage(
            text: result['response'] ?? 'No response',
            sender: SenderType.ai,
            animeCards: animeCards,
          ));
          _isAITyping = false;
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: result['error'] ?? 'Something went wrong',
            sender: SenderType.ai,
          ));
          _isAITyping = false;
        });
      }
      
      _saveChatHistory();
      _scrollToBottom();
    }
    _textController.clear();
  }

  void _clearSelectedOption() {
    setState(() => _selectedOptionText = null);
  }

  void _showOptionsBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final ColorScheme colorScheme = Theme.of(sheetContext).colorScheme;
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey.shade900.withOpacity(0.95)
                    : Colors.grey.shade100.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.search, color: colorScheme.primary),
                    title: Text('Search Anime',
                        style: TextStyle(color: colorScheme.onSurface)),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() => _selectedOptionText = 'Search Anime');
                      _textController.clear();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.lightbulb_outline, color: colorScheme.tertiary),
                    title: Text('Suggestions',
                        style: TextStyle(color: colorScheme.onSurface)),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() => _selectedOptionText = 'Suggestions');
                      _textController.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: _MessageList(
                    scrollController: _scrollController,
                    messages: _messages,
                    isAITyping: _isAITyping,
                    onEdit: (message) {
                      setState(() {
                        _editingMessage = message;
                        _textController.text = message.text;
                      });
                    },
                  ),
                ),
                _ChatInputArea(
                  textController: _textController,
                  onSendMessage: _handleSendMessage,
                  onPlusPressed: _showOptionsBottomSheet,
                  isEditing: _editingMessage != null,
                  selectedOptionText: _selectedOptionText,
                  onClearSelectedOption: _clearSelectedOption,
                  onCancelEdit: () {
                    setState(() {
                      _editingMessage = null;
                      _textController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
          _buildTopBar(topPadding, context),
        ],
      ),
    );
  }

  Widget _buildTopBar(double topPadding, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.black54;

    return Positioned(
      top: topPadding + 8.0,
      left: 16.0,
      right: 16.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _GlassPillContainer(
            onTap: widget.onMenuPressed,
            isCircle: true,
            child: Icon(
              Icons.menu,
              color: iconColor,
              size: 24.0,
            ),
          ),
          _GlassPillContainer(
            child: Text(
              'Hisu Ai',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          _GlassPillContainer(
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: iconColor,
                  size: 24.0,
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.more_vert_rounded,
                  color: iconColor,
                  size: 24.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Drawer Screen ---
class HisuDrawerScreen extends StatelessWidget {
  final VoidCallback onClose;
  const HisuDrawerScreen({super.key, required this.onClose});

  Future<void> _handleRefresh(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 1));
    await HisuHandler.clearChatHistory();
    // Trigger rebuild by closing and reopening
    onClose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Hisu Ai', style: theme.textTheme.headlineSmall),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(context),
        color: isDark ? Colors.white : Colors.black,
        backgroundColor: isDark ? Colors.black : Colors.white,
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: isDark ? Colors.white : Colors.black),
              title: Text('New Chat', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              onTap: () async {
                await HisuHandler.clearChatHistory();
                onClose();
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined, color: isDark ? Colors.white : Colors.black),
              title: Text('Settings', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              onTap: () {
                onClose();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- Widgets ---
class _GlassPillContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isCircle;

  const _GlassPillContainer({
    required this.child,
    this.onTap,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = isCircle ? 50.0 : 50.0;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              padding: isCircle 
                  ? const EdgeInsets.all(10.0)
                  : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: const Color(0xFF212121).withOpacity(0.4),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  final ScrollController scrollController;
  final List<ChatMessage> messages;
  final bool isAITyping;
  final Function(ChatMessage) onEdit;

  const _MessageList({
    required this.scrollController,
    required this.messages,
    required this.isAITyping,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      controller: scrollController,
      padding: const EdgeInsets.only(top: 100.0, left: 10.0, right: 10.0, bottom: 8.0),
      itemCount: messages.length + (isAITyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isAITyping) {
          return const _TypingIndicator();
        }
        final message = messages[index];
        return _ChatMessageBubble(
          message: message,
          onEdit: () => onEdit(message),
        );
      },
    );
  }
}

class _ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback onEdit;

  const _ChatMessageBubble({required this.message, required this.onEdit});

  @override
  State<_ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<_ChatMessageBubble> {
  String _animatedText = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.message.sender == SenderType.ai) {
      _animateText(widget.message.text);
    } else {
      _animatedText = widget.message.text;
    }
  }

  @override
  void didUpdateWidget(covariant _ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.text != oldWidget.message.text) {
      _timer?.cancel();
      if (widget.message.sender == SenderType.ai) {
        _animateText(widget.message.text);
      } else {
        setState(() {
          _animatedText = widget.message.text;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _animateText(String text) {
    const typingSpeed = Duration(milliseconds: 30);
    final words = text.split(' ');
    _animatedText = '';

    _timer = Timer.periodic(typingSpeed, (timer) {
      if (words.isNotEmpty) {
        setState(() {
          _animatedText += '${words.removeAt(0)} ';
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.message.sender == SenderType.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2b2b2b) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _animatedText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isUser ? Colors.white : Colors.white,
              ),
            ),
            if (widget.message.animeCards.isNotEmpty)
              ...widget.message.animeCards.map((card) => _AnimeCardWidget(card: card)),
          ],
        ),
      ),
    );
  }
}

class _ChatInputArea extends StatelessWidget {
  final TextEditingController textController;
  final VoidCallback onSendMessage;
  final VoidCallback onPlusPressed;
  final bool isEditing;
  final String? selectedOptionText;
  final VoidCallback? onClearSelectedOption;
  final VoidCallback onCancelEdit;

  const _ChatInputArea({
    required this.textController,
    required this.onSendMessage,
    required this.onPlusPressed,
    required this.isEditing,
    this.selectedOptionText,
    this.onClearSelectedOption,
    required this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0)
              .copyWith(bottom: MediaQuery.of(context).padding.bottom + 8.0),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withOpacity(0.85),
          ),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: Icon(isEditing ? Icons.cancel : Icons.add_circle_outline),
                onPressed: isEditing ? onCancelEdit : onPlusPressed,
                color: Colors.white,
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: TextField(
                      controller: textController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Colors.grey.shade800.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 12.0),
                      ),
                      onSubmitted: (_) => onSendMessage(),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                icon: const Icon(Icons.arrow_upward_rounded),
                onPressed: onSendMessage,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 22.0),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[400]! : Colors.grey[100]!,
          child: Text(
            'Thinking...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimeCardWidget extends StatelessWidget {
  final AnimeCard card;

  const _AnimeCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 5.0),
          Text('Type: ${card.type}', style: theme.textTheme.bodySmall),
          Text('Source: ${card.source}', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
