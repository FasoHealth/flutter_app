import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
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
  bool _loading = true;
  String _myId = '';
  bool _isSending = false;

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;

  XFile? _pendingFile;
  String? _pendingType;

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
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _recordTimer?.cancel();
    super.dispose();
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

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMedia() async {
    final XFile? file = await _picker.pickMedia();
    if (file == null) return;
    setState(() {
      _pendingFile = file;
      _pendingType = file.name.endsWith('.mp4') || file.name.endsWith('.mov') ? 'video' : 'image';
    });
  }

  Future<void> _takePhoto() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    setState(() {
      _pendingFile = file;
      _pendingType = 'image';
    });
  }

  Future<void> _sendPending() async {
    if (_pendingFile == null || _isSending) return;
    setState(() => _isSending = true);
    final ok = await ApiService.sendMessage(
      widget.incidentId, 
      _pendingType == 'audio' ? "Message vocal" : "Fichier joint", 
      file: _pendingFile, 
      type: _pendingType
    );
    if (mounted) {
      if (ok) {
        setState(() {
          _pendingFile = null;
          _pendingType = null;
        });
        await _load();
      }
      setState(() => _isSending = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      _recordTimer?.cancel();
      setState(() => _isRecording = false);
      if (path != null) {
        setState(() {
          _pendingFile = XFile(path);
          _pendingType = 'audio';
        });
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        String? path;
        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory();
          path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
        await _audioRecorder.start(const RecordConfig(), path: path ?? '');
        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) setState(() => ++_recordDuration);
        });
      }
    }
  }

  Future<void> _sendText() async {
    if (_controller.text.trim().isEmpty || _isSending) return;
    final content = _controller.text.trim();
    setState(() => _isSending = true);
    final ok = await ApiService.sendMessage(widget.incidentId, content);
    if (mounted) {
      if (ok) {
        _controller.clear();
        await _load();
      }
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B141A) : AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1F2B) : AppTheme.brandNavy,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Text(widget.incidentTitle[0], style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.incidentTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                  const Text('En ligne', style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final m = _messages[index];
                    return _buildMessage(m, m.senderId == _myId, isDark);
                  },
                ),
              ),
              if (_pendingType == 'audio')
                _AudioPreviewBar(
                  path: _pendingFile!.path,
                  isDark: isDark,
                  isSending: _isSending,
                  onDelete: () => setState(() { _pendingFile = null; _pendingType = null; }),
                  onSend: _sendPending,
                )
              else
                _buildInputArea(isDark),
            ],
          ),
          if (_pendingType != null && _pendingType != 'audio') _buildMediaPreviewOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildMediaPreviewOverlay(bool isDark) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.9),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() { _pendingFile = null; _pendingType = null; })),
                const Spacer(),
                const Text('Aperçu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 500),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: kIsWeb 
                    ? Image.network(_pendingFile!.path, fit: BoxFit.contain) 
                    : Image.file(File(_pendingFile!.path), fit: BoxFit.contain),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    backgroundColor: AppTheme.brandOrange,
                    onPressed: _isSending ? null : _sendPending,
                    child: _isSending 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(MessageModel m, bool isMe, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(2),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: isMe 
            ? (isDark ? const Color(0xFF4A2B10) : const Color(0xFFFEF3ED)) 
            : (isDark ? const Color(0xFF202C33) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: Radius.circular(isMe ? 10 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 10),
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1, offset: const Offset(0, 1))],
          border: isMe ? Border.all(color: AppTheme.brandOrange.withOpacity(0.1)) : null,
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (m.type == 'image' && m.attachments.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(m.attachments.first['path']!, fit: BoxFit.cover),
                ),
              if ((m.type == 'audio' || m.type == 'voice') && m.attachments.isNotEmpty)
                _AudioPlayerBubble(
                  url: m.attachments.first['path']!, 
                  isMe: isMe, 
                  senderName: m.senderName, 
                  createdAt: m.createdAt, 
                  isDark: isDark
                ),
              if (m.type == 'text' && m.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(m.content, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${m.createdAt.hour}:${m.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black45),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 15, color: AppTheme.blue),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF202C33) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.emoji_emotions_outlined, color: isDark ? Colors.white60 : AppTheme.textMuted), onPressed: () {}),
                  if (_isRecording)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.mic, color: Colors.red, size: 20),
                            const SizedBox(width: 5),
                            Text('${(_recordDuration ~/ 60).toString().padLeft(2, '0')}:${(_recordDuration % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14)),
                            const Expanded(
                              child: Text('   Glisser pour annuler', style: TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: const InputDecoration(hintText: 'Message', border: InputBorder.none),
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                  if (!_isRecording) ...[
                    IconButton(icon: Icon(Icons.attach_file, color: isDark ? Colors.white60 : AppTheme.textMuted), onPressed: _pickMedia),
                    if (_controller.text.isEmpty)
                      IconButton(icon: Icon(Icons.camera_alt, color: isDark ? Colors.white60 : AppTheme.textMuted), onPressed: _takePhoto),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: _controller.text.isNotEmpty ? _sendText : _toggleRecording,
            child: CircleAvatar(
              backgroundColor: const Color(0xFF00A884), // WhatsApp Green
              radius: 24,
              child: Icon(_controller.text.isNotEmpty ? Icons.send : (_isRecording ? Icons.stop : Icons.mic), color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioPreviewBar extends StatefulWidget {
  final String path;
  final bool isDark;
  final bool isSending;
  final VoidCallback onDelete;
  final VoidCallback onSend;

  const _AudioPreviewBar({required this.path, required this.isDark, required this.isSending, required this.onDelete, required this.onSend});

  @override
  State<_AudioPreviewBar> createState() => _AudioPreviewBarState();
}

class _AudioPreviewBarState extends State<_AudioPreviewBar> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _stateSub;
  StreamSubscription? _durSub;
  StreamSubscription? _posSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.onPlayerStateChanged.listen((s) { if (mounted) setState(() => _isPlaying = s == PlayerState.playing); });
    _durSub = _player.onDurationChanged.listen((d) { if (mounted) setState(() => _duration = d); });
    _posSub = _player.onPositionChanged.listen((p) { if (mounted) setState(() => _position = p); });
  }

  @override
  void dispose() { _stateSub?.cancel(); _durSub?.cancel(); _posSub?.cancel(); _player.dispose(); super.dispose(); }

  void _play() async {
    if (_isPlaying) await _player.pause();
    else {
      Source source = kIsWeb ? UrlSource(widget.path) : DeviceFileSource(widget.path);
      await _player.play(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    double maxVal = _duration.inSeconds.toDouble();
    if (maxVal <= 0) maxVal = 1.0;
    double currentVal = _position.inSeconds.toDouble().clamp(0.0, maxVal);

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF202C33) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1)],
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: widget.onDelete),
                  IconButton(icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: widget.isDark ? Colors.white70 : Colors.black87), onPressed: _play),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: const Color(0xFF00A884),
                        inactiveTrackColor: Colors.grey[300],
                        thumbColor: const Color(0xFF00A884),
                      ),
                      child: Slider(
                        value: currentVal,
                        max: maxVal,
                        onChanged: (v) => _player.seek(Duration(seconds: v.toInt())),
                      ),
                    ),
                  ),
                  Text('${(_isPlaying ? _position : _duration).inMinutes}:${((_isPlaying ? _position : _duration).inSeconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.mic, color: Color(0xFFE91E63), size: 18)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: widget.isSending ? null : widget.onSend,
            child: CircleAvatar(
              backgroundColor: const Color(0xFF00A884),
              radius: 24,
              child: widget.isSending 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioPlayerBubble extends StatefulWidget {
  final String url;
  final bool isMe;
  final String senderName;
  final DateTime createdAt;
  final bool isDark;
  final bool isLocal;

  const _AudioPlayerBubble({
    required this.url, 
    required this.isMe, 
    required this.senderName, 
    required this.createdAt, 
    required this.isDark,
    this.isLocal = false,
  });

  @override
  State<_AudioPlayerBubble> createState() => _AudioPlayerBubbleState();
}

class _AudioPlayerBubbleState extends State<_AudioPlayerBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  StreamSubscription? _stateSub;
  StreamSubscription? _durSub;
  StreamSubscription? _posSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() { 
    _stateSub?.cancel();
    _durSub?.cancel();
    _posSub?.cancel();
    _player.dispose(); 
    super.dispose(); 
  }

  void _play() async {
    if (_isPlaying) await _player.pause();
    else {
      Source source;
      if (widget.isLocal) {
        if (kIsWeb) source = UrlSource(widget.url);
        else source = DeviceFileSource(widget.url);
      } else {
        source = UrlSource(widget.url);
      }
      await _player.play(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    double maxVal = _duration.inSeconds.toDouble();
    if (maxVal <= 0) maxVal = 1.0;
    double currentVal = _position.inSeconds.toDouble().clamp(0.0, maxVal);

    return Container(
      width: 250,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    child: Text(widget.senderName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.brandNavy)),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                      child: const Icon(Icons.mic, color: AppTheme.brandOrange, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _play,
                child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppTheme.brandNavy.withOpacity(0.6), size: 30),
              ),
              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: AppTheme.brandOrange,
                        inactiveTrackColor: Colors.black12,
                        thumbColor: AppTheme.brandNavy,
                      ),
                      child: Slider(
                        value: currentVal,
                        max: maxVal,
                        onChanged: (v) => _player.seek(Duration(seconds: v.toInt())),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_format( _isPlaying ? _position : _duration), style: TextStyle(fontSize: 11, color: widget.isDark ? Colors.white60 : Colors.black45)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!widget.isLocal)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${widget.createdAt.hour}:${widget.createdAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 10, color: Colors.black45)),
                if (widget.isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 14, color: AppTheme.blue),
                ],
              ],
            ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
