import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String myUserId = Supabase.instance.client.auth.currentUser!.id;
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

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
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
