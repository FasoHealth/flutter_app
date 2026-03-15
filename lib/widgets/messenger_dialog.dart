import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../pages/profile_page.dart';

class MessengerDialog extends StatefulWidget {
  final String incidentId;
  final String incidentTitle;

  const MessengerDialog({
    super.key,
    required this.incidentId,
    required this.incidentTitle,
  });

  @override
  State<MessengerDialog> createState() => _MessengerDialogState();
}

class _MessengerDialogState extends State<MessengerDialog> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String _myId = '';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final msgs = await ApiService.getIncidentMessages(widget.incidentId);
    final id = await ApiService.getUserId();
    if (mounted) {
      setState(() {
        _messages = msgs;
        _myId = id ?? '';
        _isLoading = false;
      });
      _scrollToBottom();
    }
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

  Future<void> _send() async {
    if (_controller.text.trim().isEmpty || _isSending) return;
    final content = _controller.text.trim();
    
    setState(() => _isSending = true);
    
    final ok = await ApiService.sendMessage(widget.incidentId, content);
    if (mounted) {
      if (ok) {
        _controller.clear();
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: Le message n\'a pas pu être envoyé.'))
        );
      }
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
    final textDim = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: textDim.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.accentPurple.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.forum_rounded, color: AppTheme.accentPurple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assistance Signalement', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(widget.incidentTitle, style: TextStyle(color: textDim, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded))
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Messages List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty 
                ? _buildEmptyState(textDim)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final isMe = m.senderId == _myId;
                      return _buildMessageBubble(m, isMe, textDim);
                    },
                  ),
          ),
          
          // Input
          Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
              color: cardBg,
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              border: isDark ? Border(top: BorderSide(color: Colors.white.withOpacity(0.05))) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    readOnly: _isSending,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      fillColor: isDark ? const Color(0xFF111827) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 12),
                _isSending 
                  ? const SizedBox(width: 48, height: 48, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                  : CircleAvatar(
                      backgroundColor: AppTheme.accentPurple,
                      child: IconButton(onPressed: _send, icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel m, bool isMe, Color textDim) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.accentPurple : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) 
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: m.senderId))),
                child: Text(m.senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.accentPurple)),
              ),
            if (!isMe) const SizedBox(height: 2),
            Text(
              m.content, 
              style: TextStyle(
                color: isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87), 
                fontSize: 14,
                height: 1.4,
              )
            ),
            const SizedBox(height: 4),
            Text(
              '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: isMe ? Colors.white60 : textDim, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textDim) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: textDim.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('Démarrez la conversation', style: TextStyle(color: textDim, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Posez vos questions ou donnez des détails.', style: TextStyle(color: textDim.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }
}
