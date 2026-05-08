import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/services/notification_service.dart';
import 'package:sahara_club_spa_app/features/therapist/data/therapist_repository.dart';

// ── Messages list ─────────────────────────────────────────────────────────────

class TherapistMessagesPage extends StatefulWidget {
  final TherapistRepository repo;
  const TherapistMessagesPage({super.key, required this.repo});

  @override
  State<TherapistMessagesPage> createState() => _TherapistMessagesPageState();
}

class _TherapistMessagesPageState extends State<TherapistMessagesPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final raw = await widget.repo.getStaffContacts();
    if (!mounted) return;
    setState(() {
      _contacts = raw;
      _loading  = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(
          color: SaharaColors.gold, strokeWidth: 1.5));
    }
    if (_contacts.isEmpty) return _buildEmpty();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      itemCount: _contacts.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) return _buildInfoBanner();
        return _buildContactTile(_contacts[i - 1]);
      },
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SaharaColors.gold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: SaharaColors.gold, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mensajes internos con el equipo de Sahara Club.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: SaharaColors.grayText, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(Map<String, dynamic> c) {
    final name = c['full_name'] as String? ?? 'Staff';
    final role = c['role']     as String? ?? '';

    final initials = name.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final roleLabel = role == 'admin' ? 'Administrador' : 'Recepcionista';
    final roleColor = role == 'admin'
        ? const Color(0xFFC6A76A)
        : const Color(0xFF64B5F6);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TherapistChatPage(
          repo:        widget.repo,
          contactId:   c['id'] as String,
          contactName: name,
          roleLabel:   roleLabel,
        )),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: roleColor.withValues(alpha: 0.3)),
              ),
              child: Center(child: Text(initials, style: GoogleFonts.inter(
                fontSize: 15, color: roleColor,
                fontWeight: FontWeight.w700,
              ))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.inter(
                    fontSize: 14, color: SaharaColors.whiteSoft,
                    fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(roleLabel, style: GoogleFonts.inter(
                      fontSize: 9, color: roleColor,
                      fontWeight: FontWeight.w700, letterSpacing: 0.5,
                    )),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: SaharaColors.grayText, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: SaharaColors.gold.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(
                  color: SaharaColors.gold.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: SaharaColors.gold, size: 40),
          ),
          const SizedBox(height: 20),
          Text('Sin contactos disponibles',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18, color: SaharaColors.whiteSoft,
              fontWeight: FontWeight.w300,
            )),
          const SizedBox(height: 8),
          Text('Agrega personal para habilitar los mensajes.',
            style: GoogleFonts.inter(
                fontSize: 13, color: SaharaColors.grayText)),
        ],
      ),
    );
  }
}

// ── Chat page ─────────────────────────────────────────────────────────────────

class TherapistChatPage extends StatefulWidget {
  final TherapistRepository repo;
  final String contactId;
  final String contactName;
  final String roleLabel;

  const TherapistChatPage({
    super.key,
    required this.repo,
    required this.contactId,
    required this.contactName,
    required this.roleLabel,
  });

  @override
  State<TherapistChatPage> createState() => _TherapistChatPageState();
}

class _TherapistChatPageState extends State<TherapistChatPage> {
  final _textCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();

  String? _chatId;
  Stream<List<Map<String, dynamic>>>? _stream;
  bool _initializing = true;
  bool _sending      = false;
  int _limit = 10;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _initChat();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 50) {
      if (_chatId != null && _stream != null) {
        setState(() {
          _limit += 10;
          _stream = widget.repo.streamMessages(_chatId!, limit: _limit);
        });
      }
    }
  }

  @override
  void dispose() {
    NotificationService.instance.leaveChat();
    _scrollCtrl.removeListener(_onScroll);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      final chatId = await widget.repo.getOrCreateChat(widget.contactId);
      if (!mounted) return;
      NotificationService.instance.enterChat(chatId);
      setState(() {
        _chatId       = chatId;
        _stream       = widget.repo.streamMessages(chatId, limit: _limit);
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _initializing = false);
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _chatId == null || _sending) return;
    _textCtrl.clear();
    setState(() => _sending = true);
    try {
      await widget.repo.sendMessage(_chatId!, text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al enviar: $e',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: const Color(0xFF2A1010),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: SaharaColors.grayText, size: 16),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contactName, style: GoogleFonts.inter(
              fontSize: 15, color: SaharaColors.whiteSoft,
              fontWeight: FontWeight.w600,
            )),
            Text(widget.roleLabel, style: GoogleFonts.inter(
              fontSize: 11, color: SaharaColors.grayText,
            )),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1,
              color: SaharaColors.gold.withValues(alpha: 0.08)),
        ),
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator(
              color: SaharaColors.gold, strokeWidth: 1.5))
          : _chatId == null
              ? _buildError()
              : Column(
                  children: [
                    Expanded(child: _buildMessageList()),
                    _buildInput(),
                  ],
                ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _stream,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(
              color: SaharaColors.gold, strokeWidth: 1.5));
        }
        final msgs = snap.data!;

        if (msgs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    color: SaharaColors.grayText.withValues(alpha: 0.3),
                    size: 40),
                const SizedBox(height: 12),
                Text('Inicia la conversación',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: SaharaColors.grayText)),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollCtrl,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: msgs.length,
          itemBuilder: (_, i) {
            final msg  = msgs[i];
            final next = i < msgs.length - 1 ? msgs[i + 1] : null;
            final showDate = next == null ||
                _dayOf(msg['created_at'] as String? ?? '') !=
                _dayOf(next['created_at'] as String? ?? '');
            return Column(
              children: [
                if (showDate)
                  _DateSeparator(ts: msg['created_at'] as String?),
                _MessageBubble(
                  msg:  msg,
                  mine: msg['sender_id'] == widget.repo.myId,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
            top: BorderSide(
                color: SaharaColors.gold.withValues(alpha: 0.08))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.inter(
                  fontSize: 14, color: SaharaColors.whiteSoft),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje…',
                hintStyle: GoogleFonts.inter(
                    color: SaharaColors.grayText.withValues(alpha: 0.5)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _sending
                    ? SaharaColors.gold.withValues(alpha: 0.5)
                    : SaharaColors.gold,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.send_rounded,
                      color: Colors.black, size: 20),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Text('No se pudo abrir el chat.',
          style: GoogleFonts.inter(
              fontSize: 13, color: SaharaColors.grayText)),
    );
  }

  String _dayOf(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.year}-${d.month}-${d.day}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool mine;
  const _MessageBubble({required this.msg, required this.mine});

  @override
  Widget build(BuildContext context) {
    final content = msg['content'] as String? ?? '';
    final ts      = msg['created_at'] as String?;
    final time    = _fmtTime(ts);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: mine
              ? SaharaColors.gold.withValues(alpha: 0.15)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          border: mine
              ? Border.all(color: SaharaColors.gold.withValues(alpha: 0.3))
              : Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(content, style: GoogleFonts.inter(
              fontSize: 14,
              color: mine ? SaharaColors.whiteSoft : SaharaColors.whiteSoft,
              height: 1.4,
            )),
            const SizedBox(height: 4),
            Text(time, style: GoogleFonts.inter(
              fontSize: 10,
              color: mine
                  ? SaharaColors.gold.withValues(alpha: 0.6)
                  : SaharaColors.grayText.withValues(alpha: 0.6),
            )),
          ],
        ),
      ),
    );
  }

  String _fmtTime(String? ts) {
    if (ts == null) return '';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(ts).toLocal());
    } catch (_) {
      return '';
    }
  }
}

// ── Date separator ────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final String? ts;
  const _DateSeparator({this.ts});

  @override
  Widget build(BuildContext context) {
    String label = '';
    if (ts != null) {
      try {
        final d   = DateTime.parse(ts!).toLocal();
        final now = DateTime.now();
        if (d.day == now.day && d.month == now.month && d.year == now.year) {
          label = 'Hoy';
        } else if (d.day == now.day - 1 && d.month == now.month && d.year == now.year) {
          label = 'Ayer';
        } else {
          label = DateFormat('d MMM yyyy', 'es').format(d);
        }
      } catch (_) {}
    }
    if (label.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Container(
              height: 0.5, color: Colors.white.withValues(alpha: 0.08))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: GoogleFonts.inter(
              fontSize: 11, color: SaharaColors.grayText,
              fontWeight: FontWeight.w500,
            )),
          ),
          Expanded(child: Container(
              height: 0.5, color: Colors.white.withValues(alpha: 0.08))),
        ],
      ),
    );
  }
}
