import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/web_theme.dart';

class DesktopChatPane extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String productTitle;
  final VoidCallback? onClose;

  const DesktopChatPane({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.productTitle,
    this.onClose,
  });

  @override
  State<DesktopChatPane> createState() => _DesktopChatPaneState();
}

class _DesktopChatPaneState extends State<DesktopChatPane> {
  final _messageController = TextEditingController();
  final _picker = ImagePicker();

  bool _isUploading = false;
  XFile? _selectedImage;

  final String myUserId = Supabase.instance.client.auth.currentUser!.id;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final image = _selectedImage;

    if (text.isEmpty && image == null) return;

    setState(() => _isUploading = true);

    String? imageUrl;

    try {
      // 1. Upload image if selected
      if (image != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$myUserId.jpg';
        final path = '${widget.chatId}/$fileName';

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          await Supabase.instance.client.storage.from('chat_images').uploadBinary(path, bytes);
        } else {
          await Supabase.instance.client.storage.from('chat_images').upload(path, File(image.path));
        }

        imageUrl = Supabase.instance.client.storage.from('chat_images').getPublicUrl(path);
      }

      // 2. Insert message
      await Supabase.instance.client.from('messages').insert({
        'chat_id': widget.chatId,
        'sender_id': myUserId,
        'text_content': text.isNotEmpty ? text : null,
        'image_url': imageUrl,
      });

      // 3. Clear UI
      _messageController.clear();
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim pesan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: WebTheme.border)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: WebTheme.primary,
                  child: Text(
                    widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherUserName,
                        style: WebTheme.navLink.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 13, color: WebTheme.accent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Terkait: ${widget.productTitle}',
                              style: WebTheme.navLink.copyWith(
                                fontSize: 12,
                                color: WebTheme.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: WebTheme.textSecondary),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),

          // Messages Stream
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('messages')
                    .stream(primaryKey: ['id'])
                    .eq('chat_id', widget.chatId)
                    .order('created_at', ascending: true),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: WebTheme.accent));
                  }

                  final rawMessages = snapshot.data ?? [];

                  // Deduplicate messages
                  final Map<String, Map<String, dynamic>> uniqueMessages = {};
                  for (var msg in rawMessages) {
                    uniqueMessages[msg['id']] = msg;
                  }
                  final messages = uniqueMessages.values.toList();
                  messages.sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 48, color: WebTheme.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada pesan. Sapa sekarang!',
                            style: WebTheme.navLink.copyWith(color: WebTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['sender_id'] == myUserId;
                      final text = msg['text_content'];
                      final img = msg['image_url'];

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 480),
                          decoration: BoxDecoration(
                            color: isMe ? WebTheme.primary : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(isMe ? 14 : 2),
                              bottomRight: Radius.circular(isMe ? 2 : 14),
                            ),
                            border: isMe ? null : Border.all(color: WebTheme.border),
                            boxShadow: isMe ? null : WebTheme.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (img != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(img, fit: BoxFit.cover),
                                ),
                                if (text != null) const SizedBox(height: 8),
                              ],
                              if (text != null)
                                Text(
                                  text,
                                  style: WebTheme.navLink.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: isMe ? Colors.white : WebTheme.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          if (_isUploading) const LinearProgressIndicator(color: WebTheme.accent),

          // Image Preview Area
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xFFF1F5F9),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: WebTheme.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                              : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: -10,
                        right: -10,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: WebTheme.error, size: 20),
                          onPressed: () => setState(() => _selectedImage = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Gambar siap dikirim.\nKetik pesan di bawah lalu tekan kirim.',
                      style: WebTheme.navLink.copyWith(fontSize: 12, color: WebTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: WebTheme.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined, color: WebTheme.textSecondary),
                  tooltip: 'Kirim Gambar',
                  onPressed: _isUploading ? null : _pickImage,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: WebTheme.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isUploading,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Ketik pesan...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isUploading ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WebTheme.accent,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.send, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
