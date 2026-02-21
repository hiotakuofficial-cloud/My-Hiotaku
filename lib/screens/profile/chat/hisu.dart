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
  void initState() {
    super.initState();
    // Set transparent status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

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
  final bool skipAnimation;

  const ChatMessage({
    required this.text,
    required this.sender,
    this.animeCards = const [],
    this.skipAnimation = false,
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
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveChatHistory();
    _scrollController.removeListener(_onScroll);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // If user scrolls up manually, disable auto scroll
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      // If user is near bottom (within 100px), enable auto scroll
      if (maxScroll - currentScroll < 100) {
        _autoScroll = true;
      } else {
        _autoScroll = false;
      }
    }
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
          skipAnimation: true, // Skip animation for loaded history
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
    if (!_autoScroll) return; // Don't force scroll if user scrolled up
    
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

  String _buildConversationContext() {
    // Build context from last 5 messages (max 500 chars)
    final recentMessages = _messages.length > 5 
        ? _messages.sublist(_messages.length - 5)
        : _messages;
    
    final context = recentMessages.map((msg) {
      final sender = msg.sender == SenderType.user ? 'User' : 'Hisu';
      return '$sender: ${msg.text}';
    }).join(' '); // Use space instead of newline for HTTP header compatibility
    
    return context.length > 500 ? context.substring(context.length - 500) : context;
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
      _textController.clear();
    } else {
      // Clear input immediately
      _textController.clear();
      
      // Enable auto scroll when sending message
      _autoScroll = true;
      
      setState(() {
        _messages.add(ChatMessage(text: text, sender: SenderType.user));
        _isAITyping = true;
      });
      
      _scrollToBottom();

      // Build conversation context from recent messages
      final context = _buildConversationContext();
      final result = await HisuHandler.sendMessage(text, conversationContext: context);

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
  }

  void _handleStopGeneration() {
    setState(() {
      _isAITyping = false;
    });
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
        
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
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
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.search, color: Colors.white),
                    title: const Text('Search Anime',
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() => _selectedOptionText = 'Search Anime');
                      _textController.clear();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lightbulb_outline, color: Colors.white),
                    title: const Text('Suggestions',
                        style: TextStyle(color: Colors.white)),
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
      backgroundColor: const Color(0xFF111112),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: <Widget>[
          Column(
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
                  onScrollToBottom: _scrollToBottom,
                ),
              ),
              _ChatInputArea(
                textController: _textController,
                onSendMessage: _handleSendMessage,
                onStopGeneration: _handleStopGeneration,
                onPlusPressed: _showOptionsBottomSheet,
                isEditing: _editingMessage != null,
                isAITyping: _isAITyping,
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
          _buildTopBar(topPadding, context),
        ],
      ),
    );
  }

  Widget _buildTopBar(double topPadding, BuildContext context) {
    return Positioned(
      top: topPadding + 8.0,
      left: 16.0,
      right: 16.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: [
              _GlassPillContainer(
                onTap: widget.onMenuPressed,
                isCircle: true,
                child: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 24.0,
                ),
              ),
              const SizedBox(width: 12),
              _GlassPillContainer(
                child: Text(
                  'Hisu Ai',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          _GlassPillContainer(
            child: const Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 24.0,
                ),
                SizedBox(width: 12),
                Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
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
      backgroundColor: const Color(0xFF121212),
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(context),
        color: Colors.white,
        backgroundColor: const Color(0xFF121212),
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hisu Ai',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.white),
              title: const Text('New Chat', style: TextStyle(color: Colors.white)),
              onTap: () async {
                await HisuHandler.clearChatHistory();
                onClose();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.white),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
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
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              padding: isCircle 
                  ? const EdgeInsets.all(10.0)
                  : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: const Color(0xFF212121).withOpacity(0.6),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 0.2,
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
  final VoidCallback? onScrollToBottom;

  const _MessageList({
    required this.scrollController,
    required this.messages,
    required this.isAITyping,
    required this.onEdit,
    this.onScrollToBottom,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      controller: scrollController,
      padding: const EdgeInsets.only(top: 100.0, left: 10.0, right: 10.0, bottom: 8.0),
      itemCount: messages.length + (isAITyping ? 1 : 0),
      cacheExtent: 1000, // Pre-render items for smooth scrolling
      itemBuilder: (context, index) {
        if (index == messages.length && isAITyping) {
          return const _TypingIndicator();
        }
        final message = messages[index];
        final isLastMessage = index == messages.length - 1;
        return _ChatMessageBubble(
          key: ValueKey('${message.text}_$index'), // Unique key for each message
          message: message,
          onEdit: () => onEdit(message),
          onWordAdded: (isLastMessage && message.sender == SenderType.ai && onScrollToBottom != null) 
              ? onScrollToBottom 
              : null,
        );
      },
    );
  }
}

class _ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback onEdit;
  final VoidCallback? onWordAdded;

  const _ChatMessageBubble({
    super.key, 
    required this.message, 
    required this.onEdit,
    this.onWordAdded,
  });

  @override
  State<_ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<_ChatMessageBubble> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  String _animatedText = '';
  Timer? _timer;
  bool _hasAnimated = false;
  final List<String> _words = [];
  final List<double> _wordOpacities = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.message.sender == SenderType.ai && !_hasAnimated && !widget.message.skipAnimation) {
      _animateText(widget.message.text);
      _hasAnimated = true;
    } else {
      _animatedText = widget.message.text;
    }
  }

  @override
  void didUpdateWidget(covariant _ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.text != oldWidget.message.text && !_hasAnimated) {
      _timer?.cancel();
      if (widget.message.sender == SenderType.ai) {
        _animateText(widget.message.text);
        _hasAnimated = true;
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
    const typingSpeed = Duration(milliseconds: 100);
    final allWords = text.split(' ');
    _words.clear();
    _wordOpacities.clear();
    int currentIndex = 0;

    _timer = Timer.periodic(typingSpeed, (timer) {
      if (currentIndex < allWords.length && mounted) {
        setState(() {
          _words.add(allWords[currentIndex]);
          _wordOpacities.add(0.0);
          
          final capturedIndex = currentIndex;
          
          // Fade in current word
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted && capturedIndex < _wordOpacities.length) {
              setState(() {
                _wordOpacities[capturedIndex] = 0.5;
              });
            }
          });
          
          // Fully visible after delay
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && capturedIndex < _wordOpacities.length) {
              setState(() {
                _wordOpacities[capturedIndex] = 1.0;
              });
              // Trigger scroll after word is visible
              if (widget.onWordAdded != null) {
                widget.onWordAdded!();
              }
            }
          });
          
          currentIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final isUser = widget.message.sender == SenderType.user;
    final screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isUser ? screenWidth * 0.7 : screenWidth * 0.85,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2b2b2b) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_words.isNotEmpty && widget.message.sender == SenderType.ai)
              Wrap(
                children: List.generate(_words.length, (index) {
                  return AnimatedOpacity(
                    opacity: _wordOpacities[index],
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      '${_words[index]} ',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  );
                }),
              )
            else if (_animatedText.isNotEmpty)
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
  final VoidCallback onStopGeneration;
  final VoidCallback onPlusPressed;
  final bool isEditing;
  final bool isAITyping;
  final String? selectedOptionText;
  final VoidCallback? onClearSelectedOption;
  final VoidCallback onCancelEdit;

  const _ChatInputArea({
    required this.textController,
    required this.onSendMessage,
    required this.onStopGeneration,
    required this.onPlusPressed,
    required this.isEditing,
    required this.isAITyping,
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
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                theme.scaffoldBackgroundColor.withOpacity(0.85),
              ],
              stops: const [0.7, 1.0],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              IconButton(
                icon: Icon(isEditing ? Icons.cancel : Icons.add_circle_outline),
                onPressed: isEditing ? onCancelEdit : onPlusPressed,
                color: Colors.white,
                padding: const EdgeInsets.all(8.0),
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 120.0,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(28.0),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 0.2,
                          ),
                        ),
                        child: TextField(
                          controller: textController,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.white54),
                            filled: false,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 12.0),
                          ),
                          onSubmitted: (_) => onSendMessage(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                icon: Icon(isAITyping ? Icons.stop_rounded : Icons.arrow_upward_rounded),
                onPressed: isAITyping ? onStopGeneration : onSendMessage,
                padding: const EdgeInsets.all(8.0),
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

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 22.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[400]!,
          period: const Duration(milliseconds: 1500),
          child: Text(
            'Thinking...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
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
