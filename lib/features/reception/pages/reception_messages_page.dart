import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/services/notification_service.dart';
import 'package:sahara_club_spa_app/features/reception/data/reception_repository.dart';

// ── Contacts list ─────────────────────────────────────────────────────────────

class ReceptionMessagesPage extends StatefulWidget {
  final ReceptionRepository repo;
  const ReceptionMessagesPage({super.key, required this.repo});

  @override
  State<ReceptionMessagesPage> createState() => _ReceptionMessagesPageState();
}

class _ReceptionMessagesPageState extends State<ReceptionMessagesPage> {
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
      return const Center(
        child: CircularProgressIndicator(color: SaharaColors.gold, strokeWidth: 1.5),
      );
    }
    if (_contacts.isEmpty) {
      return Center(
        child: Text('Sin contactos disponibles',
            style: GoogleFonts.inter(fontSize: 13, color: SaharaColors.grayText)),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: SaharaColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        itemCount: _contacts.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return _buildBanner();
          return _buildCard(_contacts[i - 1]);
        },
      ),
    );
  }

  Widget _buildBanner() {
    final admins     = _contacts.where((c) => c['role'] == 'admin').length;
    final therapists = _contacts.where((c) => c['role'] == 'therapist').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: SaharaColors.gold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          _Stat(
            value: '$admins',
            label: 'Admins',
            icon: Icons.admin_panel_settings_outlined,
            color: SaharaColors.gold,
          ),
          Container(
            width: 1, height: 32, margin: const EdgeInsets.symmetric(horizontal: 12),
            color: SaharaColors.gold.withValues(alpha: 0.2),
          ),
          _Stat(
            value: '$therapists',
            label: 'Terapeutas',
            icon: Icons.self_improvement_rounded,
            color: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final name      = c['full_name'] as String? ?? 'Usuario';
    final role      = c['role']      as String? ?? '';
    final specialty = c['specialty'] as String?;
    final isAdmin   = role == 'admin';

    final color     = isAdmin ? SaharaColors.gold : const Color(0xFF4CAF50);
    final roleLabel = isAdmin ? 'Administrador' : _fmtSpecialty(specialty);

    final initials = name.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceptionChatPage(
            repo:      widget.repo,
            contactId: c['id'] as String,
            name:      name,
            roleLabel: roleLabel,
            roleColor: color,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Center(child: Text(initials, style: GoogleFonts.inter(
                fontSize: 14, color: color, fontWeight: FontWeight.w700,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(roleLabel, style: GoogleFonts.inter(
                      fontSize: 10, color: color, fontWeight: FontWeight.w500,
                    )),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: SaharaColors.grayText.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }

  String _fmtSpecialty(String? s) {
    const map = {
      'massage':        'Masajes',
      'facial':         'Faciales',
      'body_treatment': 'Corporal',
      'nail_care':      'Uñas',
      'hair_removal':   'Depilación',
      'hydrotherapy':   'Hidroterapia',
      'general':        'Terapeuta',
    };
    return map[s] ?? 'Terapeuta';
  }
}

// ── Chat page ─────────────────────────────────────────────────────────────────

class ReceptionChatPage extends StatefulWidget {
  final ReceptionRepository repo;
  final String contactId;
  final String name;
  final String roleLabel;
  final Color  roleColor;

  const ReceptionChatPage({
    super.key,
    required this.repo,
    required this.contactId,
    required this.name,
    required this.roleLabel,
    required this.roleColor,
  });

  @override
  State<ReceptionChatPage> createState() => _ReceptionChatPageState();
}

class _ReceptionChatPageState extends State<ReceptionChatPage> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();

  String? _chatId;
  Stream<List<Map<String, dynamic>>>? _stream;
  bool _initializing = true;
  int _limit = 10;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _initChat();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 50) {
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
    _scroll.removeListener(_onScroll);
    _ctrl.dispose();
    _scroll.dispose();
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
    } catch (e) {
      debugPrint('ReceptionChatPage._initChat: $e');
      if (!mounted) return;
      setState(() => _initializing = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _chatId == null) return;
    _ctrl.clear();
    try {
      await widget.repo.sendMessage(_chatId!, text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al enviar: $e'),
        backgroundColor: const Color(0xFF2A1010),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.name.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: SaharaColors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: SaharaColors.grayText, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.roleColor.withValues(alpha: 0.12),
                border: Border.all(color: widget.roleColor.withValues(alpha: 0.3)),
              ),
              child: Center(child: Text(initials, style: GoogleFonts.inter(
                fontSize: 11, color: widget.roleColor, fontWeight: FontWeight.w700,
              ))),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name, style: GoogleFonts.inter(
                  fontSize: 14, color: SaharaColors.whiteSoft,
                  fontWeight: FontWeight.w600,
                )),
                Text(widget.roleLabel, style: GoogleFonts.inter(
                  fontSize: 10, color: widget.roleColor,
                )),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1,
              color: SaharaColors.gold.withValues(alpha: 0.08)),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator(
          color: SaharaColors.gold, strokeWidth: 1.5));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _stream,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(
              color: SaharaColors.gold, strokeWidth: 1.5));
        }
        final msgs = snap.data!;
        if (msgs.isEmpty) {
          return Center(child: Text('Inicia la conversación',
              style: GoogleFonts.inter(
                  fontSize: 13, color: SaharaColors.grayText)));
        }
        return ListView.builder(
          controller: _scroll,
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
                if (showDate) _DateSep(dateStr: msg['created_at'] as String? ?? ''),
                _Bubble(
                  msg:  msg,
                  mine: (msg['sender_id'] as String?) == widget.repo.myId,
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
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(top: BorderSide(
            color: SaharaColors.gold.withValues(alpha: 0.08))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: SaharaColors.gold.withValues(alpha: 0.12)),
                ),
                child: TextField(
                  controller: _ctrl,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: SaharaColors.whiteSoft),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje…',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: SaharaColors.grayText.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SaharaColors.gold,
                  boxShadow: [
                    BoxShadow(
                      color: SaharaColors.gold.withValues(alpha: 0.3),
                      blurRadius: 8, offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.black, size: 18),
              ),
            ),
          ],
        ),
      ),
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

class _Bubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool mine;
  const _Bubble({required this.msg, required this.mine});

  @override
  Widget build(BuildContext context) {
    final content = msg['content'] as String? ?? '';
    final ts      = msg['created_at'] as String? ?? '';
    String time = '';
    try { time = DateFormat('HH:mm').format(DateTime.parse(ts).toLocal()); }
    catch (_) {}

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          border: Border.all(
            color: mine
                ? SaharaColors.gold.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(content, style: GoogleFonts.inter(
              fontSize: 14, color: SaharaColors.whiteSoft, height: 1.4,
            )),
            const SizedBox(height: 3),
            Text(time, style: GoogleFonts.inter(
              fontSize: 10,
              color: SaharaColors.grayText.withValues(alpha: 0.6),
            )),
          ],
        ),
      ),
    );
  }
}

// ── Date separator ────────────────────────────────────────────────────────────

class _DateSep extends StatelessWidget {
  final String dateStr;
  const _DateSep({required this.dateStr});

  @override
  Widget build(BuildContext context) {
    String label = '';
    try {
      final d   = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        label = 'Hoy';
      } else if (d.year == now.year && d.month == now.month &&
          d.day == now.day - 1) {
        label = 'Ayer';
      } else {
        label = DateFormat('d MMM yyyy', 'es').format(d);
      }
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Container(height: 0.5,
              color: Colors.white.withValues(alpha: 0.08))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: GoogleFonts.inter(
              fontSize: 11,
              color: SaharaColors.grayText.withValues(alpha: 0.6),
            )),
          ),
          Expanded(child: Container(height: 0.5,
              color: Colors.white.withValues(alpha: 0.08))),
        ],
      ),
    );
  }
}

// ── Banner stat ───────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.inter(
                fontSize: 18, color: color, fontWeight: FontWeight.w800,
              )),
              Text(label, style: GoogleFonts.inter(
                fontSize: 10, color: SaharaColors.grayText,
              )),
            ],
          ),
        ],
      ),
    );
  }
}
