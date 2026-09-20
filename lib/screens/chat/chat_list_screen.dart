import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/theme/web_theme.dart';
import 'chat_detail_screen.dart';
import 'desktop_chat_pane.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String myUserId = Supabase.instance.client.auth.currentUser!.id;
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  String? _selectedChatId;
  String? _selectedOtherUserName;
  String? _selectedProductTitle;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      final response = await Supabase.instance.client
          .from('chats')
          .select('*, products(title, image_urls)')
          .or('buyer_id.eq.$myUserId,seller_id.eq.$myUserId')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> enrichedChats = [];

      for (var chat in response) {
        final isBuyer = chat['buyer_id'] == myUserId;
        final otherUserId = isBuyer ? chat['seller_id'] : chat['buyer_id'];

        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', otherUserId)
            .maybeSingle();

        chat['other_user_name'] = profile?['full_name'] ?? 'Pengguna';
        enrichedChats.add(chat);
      }

      if (mounted) {
        setState(() {
          _chats = enrichedChats;
          _isLoading = false;

          // Auto-select first chat on desktop if none selected
          if (_selectedChatId == null && enrichedChats.isNotEmpty) {
            final firstChat = enrichedChats.first;
            _selectedChatId = firstChat['id'];
            _selectedOtherUserName = firstChat['other_user_name'];
            _selectedProductTitle = firstChat['products']?['title'] ?? 'Barang';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveBreakpoints.isDesktopOrTablet(context)) {
      return _buildMobileLayout(context);
    }
    return _buildDesktopLayout(context);
  }

  // DESKTOP MASTER-DETAIL 2-COLUMN LAYOUT
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: ResponsiveBreakpoints.maxChatWidth),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: WebTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WebTheme.border),
            boxShadow: WebTheme.cardShadow,
          ),
          child: Row(
            children: [
              // LEFT: CONVERSATION LIST (360px)
              SizedBox(
                width: 360,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: WebTheme.border)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pesan & Chat', style: WebTheme.sectionTitle.copyWith(fontSize: 18)),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18, color: WebTheme.textSecondary),
                            tooltip: 'Perbarui percakapan',
                            onPressed: _fetchChats,
                          ),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: WebTheme.accent))
                          : _chats.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.chat_bubble_outline, size: 48, color: WebTheme.textMuted),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Belum ada percakapan.',
                                          style: WebTheme.navLink.copyWith(color: WebTheme.textSecondary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Kirim pesan ke penjual dari halaman detail barang.',
                                          textAlign: TextAlign.center,
                                          style: WebTheme.navLink.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: WebTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _chats.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1, color: WebTheme.border),
                                  itemBuilder: (context, index) {
                                    final chat = _chats[index];
                                    final product = chat['products'] ?? {};
                                    final otherUserName = chat['other_user_name'] ?? 'Pengguna';
                                    final title = product['title'] ?? 'Barang';
                                    final isSelected = _selectedChatId == chat['id'];

                                    final imageUrls = product['image_urls'];
                                    final thumb = (imageUrls is List && imageUrls.isNotEmpty)
                                        ? imageUrls.first.toString()
                                        : null;

                                    return MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: ListTile(
                                        tileColor: isSelected ? const Color(0xFFEFF6FF) : null,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        leading: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.grey[200],
                                          backgroundImage: thumb != null ? NetworkImage(thumb) : null,
                                          child: thumb == null
                                              ? const Icon(Icons.image, color: Colors.grey, size: 20)
                                              : null,
                                        ),
                                        title: Text(
                                          otherUserName,
                                          style: WebTheme.navLink.copyWith(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                            color: isSelected ? WebTheme.accent : WebTheme.textPrimary,
                                          ),
                                        ),
                                        subtitle: Text(
                                          title,
                                          style: WebTheme.navLink.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: WebTheme.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _selectedChatId = chat['id'];
                                            _selectedOtherUserName = otherUserName;
                                            _selectedProductTitle = title;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),

              const VerticalDivider(width: 1, color: WebTheme.border),

              // RIGHT: ACTIVE CONVERSATION PANE
              Expanded(
                child: _selectedChatId != null
                    ? DesktopChatPane(
                        key: ValueKey(_selectedChatId),
                        chatId: _selectedChatId!,
                        otherUserName: _selectedOtherUserName ?? 'Pengguna',
                        productTitle: _selectedProductTitle ?? 'Barang',
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.forum_outlined, size: 64, color: WebTheme.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'Pilih percakapan',
                              style: WebTheme.sectionTitle.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pilih salah satu percakapan di sebelah kiri untuk melihat pesan.',
                              style: WebTheme.navLink.copyWith(
                                color: WebTheme.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // EXACT EXISTING MOBILE LAYOUT — ZERO REGRESSION
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pesan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? const Center(child: Text('Belum ada pesan.'))
              : ListView.separated(
                  itemCount: _chats.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    final product = chat['products'] ?? {};

                    final otherUserName = chat['other_user_name'];
                    final title = product['title'] ?? 'Barang';

                    final imageUrls = product['image_urls'];
                    final thumb = (imageUrls is List && imageUrls.isNotEmpty)
                        ? imageUrls.first.toString()
                        : null;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        backgroundImage: thumb != null ? NetworkImage(thumb) : null,
                        child: thumb == null
                            ? const Icon(Icons.image, color: Colors.grey)
                            : null,
                      ),
                      title: Text(
                        otherUserName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              chatId: chat['id'],
                              otherUserName: otherUserName,
                              productTitle: title,
                            ),
                          ),
                        ).then((_) => _fetchChats());
                      },
                    );
                  },
                ),
    );
  }
}
