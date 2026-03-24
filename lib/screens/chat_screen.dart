import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/food_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_preferences.dart';
import '../models/food_item.dart';
import 'login_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  String? _profilePhotoUrl;
  UserPreferences? _userPreferences;

  @override
  void initState() {
    super.initState();
    _addInitialSuggestions();
    _loadUserProfilePhoto();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final userData = await _databaseService
          .streamUserFlexible(uid: user.uid, email: user.email)
          .first;

      if (userData != null) {
        if (!mounted) return;
        setState(() {
          _userPreferences = UserPreferences(
            allergies: userData.allergies,
            disliked: userData.dislikes,
            liked: userData.likes,
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userPreferences = const UserPreferences();
      });
    }
  }

  Future<void> _loadUserProfilePhoto() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final fallbackPhoto = user.photoURL;

    try {
      final userData = await _databaseService
          .streamUserFlexible(uid: user.uid, email: user.email)
          .first;

      final profilePhotoUrl = (userData?.photoUrl?.isNotEmpty ?? false)
          ? userData!.photoUrl
          : fallbackPhoto;

      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = profilePhotoUrl;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = fallbackPhoto;
      });
    }
  }

  void _addInitialSuggestions() {
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              'พิมพ์วัตถุดิบที่มี เช่น ไก่ ไข่ มาม่า แล้วเราจะช่วยคิดเมนูให้ 😊',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _sendMessage(String text) async {
    if (_authService.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนใช้งานแชท')),
      );
      return;
    }

    if (text.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final result = await FoodService.search(
        query: text,
        preferences: _userPreferences ?? const UserPreferences(),
      );

      final List<FoodItem> foods = result['results'] as List<FoodItem>;
      final String message = result['message'] as String? ?? '';

      setState(() {
        if (foods.isEmpty) {
          _messages.add(
            ChatMessage(
              text: message.isNotEmpty
                  ? message
                  : 'ไม่พบเมนูที่เกี่ยวข้อง ลองพิมพ์วัตถุดิบอื่นดูนะคะ',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          _messages.add(
            ChatMessage(
              text: message.isNotEmpty
                  ? message
                  : 'พบเมนูที่แนะนำ ${foods.length} รายการค่ะ 🍽️',
              isUser: false,
              timestamp: DateTime.now(),
              foodItems: foods,
            ),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'เกิดข้อผิดพลาด: ${e.toString().replaceFirst('Exception: ', '')}',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return _buildLoginRequired(context);
        }

        return _buildChatContent(context);
      },
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF5EE),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFFB3D9),
        elevation: 0,
        title: const Text(
          'Chatbot AI',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey[500]),
              const SizedBox(height: 16),
              const Text(
                'ต้องเข้าสู่ระบบก่อนใช้งานแชท',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'เข้าสู่ระบบเพื่อให้ระบบแนะนำเมนูตามข้อมูลโปรไฟล์ของคุณ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEE6983),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatContent(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF5EE),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFFB3D9),
        elevation: 0,
        title: const Text(
          'Chatbot AI',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
                if (_isLoading)
                  const Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          color: Color(0xFFEE6983),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          hintText: 'พิมพ์วัตถุดิบที่มี เช่น ไก่ ไข่ มาม่า 🍳',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 14,
                          ),
                        ),
                        onSubmitted: _sendMessage,
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFEE6983),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final hasUserPhoto = (_profilePhotoUrl?.isNotEmpty ?? false);
    final isBotMessage = !message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFFFB3D9),
                  child: const Icon(
                    Icons.smart_toy,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: message.isError
                        ? const Color(0xFFFFE0E0)
                        : message.isUser
                        ? const Color(0xFFEE6983)
                        : null,
                    gradient: isBotMessage && !message.isError
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFF9FD), Color(0xFFFFF2F7)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(18),
                    border: message.isUser
                        ? null
                        : Border.all(
                            color: message.isError
                                ? const Color(0xFFEE6983)
                                : const Color(0xFFF3CADB),
                          ),
                    boxShadow: isBotMessage
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEE6983).withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isBotMessage && !message.isError)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: Color(0xFFEE6983),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'LovelyMeal AI',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB94C72),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      if (isBotMessage && !message.isError)
                        const SizedBox(height: 4),
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: message.isUser
                              ? Colors.white
                              : const Color(0xFF333333),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFD1D1D1),
                  foregroundImage: hasUserPhoto
                      ? NetworkImage(_profilePhotoUrl!)
                      : null,
                  child: hasUserPhoto
                      ? null
                      : const Icon(Icons.person, size: 18, color: Colors.white),
                ),
              ],
            ],
          ),
          if (!message.isUser &&
              message.foodItems != null &&
              message.foodItems!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 6),
              child: Column(
                children: message.foodItems!
                    .map((food) => _buildFoodCard(food))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(FoodItem food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBFD), Color(0xFFF8F8F8)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7C8D7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEE6983).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu_rounded,
                size: 18,
                color: Color(0xFFC2527C),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showFoodDetails(food),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E0B3D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'ดูเพิ่มเติม !',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumberedIngredients(List<String> ingredients) {
    final cleaned = ingredients
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (cleaned.isEmpty) {
      return '-';
    }

    return cleaned
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n');
  }

  void _showFoodDetails(FoodItem food) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7D7D7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'วัตถุดิบทั้งหมด',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B5670),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF9FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCAE9FA)),
                    ),
                    child: Text(
                      _formatNumberedIngredients(food.ingredients),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2E4A59),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'วิธีทำอาหาร',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8E0B3D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (food.instructions.isEmpty)
                    const Text(
                      'ยังไม่มีข้อมูลวิธีทำสำหรับเมนูนี้',
                      style: TextStyle(fontSize: 15, color: Color(0xFF555555)),
                    )
                  else
                    ...food.instructions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF333333),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<FoodItem>? foodItems;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.foodItems,
    this.isError = false,
  });
}
