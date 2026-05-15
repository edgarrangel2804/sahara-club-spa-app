import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/services/notification_service.dart';
import 'package:sahara_club_spa_app/features/client/data/client_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — tab de Mensajes del cliente
// Carga las recepcionistas y abre el chat directamente si solo hay una.
// ─────────────────────────────────────────────────────────────────────────────

class ClientMessagesPage extends StatefulWidget {
  const ClientMessagesPage({super.key});

  @override
  State<ClientMessagesPage> createState() => _ClientMessagesPageState();
}

class _ClientMessagesPageState extends State<ClientMessagesPage> {
  final _repo = ClientRepository();

  bool   _loading = true;
  List<Map<String, dynamic>> _receptionists = [];

  // Cuando solo hay una recepcionista (caso normal), se muestra el chat directo.
  String? _directId;
  String? _directName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.getReceptionists();
    if (!mounted) return;
    setState(() {
      _receptionists = list;
      _loading       = false;
      if (list.length == 1) {
        _directId   = list[0]['id']        as String?;
        _directName = list[0]['full_name'] as String? ?? 'Recepción';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain),
        child: const Center(
          child: CircularProgressIndicator(
              color: SaharaColors.gold, strokeWidth: 1.5),
        ),
      );
    }

    if (_receptionists.isEmpty) {
      return Container(
        decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.support_agent_outlined,
                    size: 56,
                    color: SaharaColors.gold.withValues(alpha: 0.35)),
                const SizedBox(height: 18),
                Text('Sin recepcionistas disponibles',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        color: SaharaColors.whiteSoft.withValues(alpha: 0.7))),
                const SizedBox(height: 10),
                Text('Intenta más tarde o contáctanos por otro medio.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: SaharaColors.grayText,
                        height: 1.5)),
                const SizedBox(height: 28),
                TextButton(
                  onPressed: _load,
                  child: Text('Reintentar',
                      style: GoogleFonts.inter(
                          color: SaharaColors.gold, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Caso normal: una sola recepcionista → chat directo
    if (_directId != null) {
      return _ClientChatView(
        repo:        _repo,
        contactId:   _directId!,
        contactName: _directName!,
      );
    }

    // Caso múltiples recepcionistas → lista de selección
    return _ReceptionistList(
      receptionists: _receptionists,
      repo:          _repo,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista de recepcionistas (solo si hay más de una)
// ─────────────────────────────────────────────────────────────────────────────

class _ReceptionistList extends StatelessWidget {
  final List<Map<String, dynamic>> receptionists;
  final ClientRepository repo;

  const _ReceptionistList({
    required this.receptionists,
    required this.repo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Container(
        decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 6),
                child: Text('Mensajes',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        color: SaharaColors.whiteSoft,
                        fontWeight: FontWeight.w400)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                child: Text('Comunícate con nuestro equipo de recepción',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: SaharaColors.grayText)),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: receptionists.length,
                  itemBuilder: (_, i) {
                    final r    = receptionists[i];
                    final name = r['full_name'] as String? ?? 'Recepción';
                    final initials = name.trim().split(' ')
                        .where((w) => w.isNotEmpty)
                        .take(2)
                        .map((w) => w[0].toUpperCase())
                        .join();
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _ClientChatView(
                            repo:        repo,
                            contactId:   r['id'] as String,
                            contactName: name,
                          ),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E0E0E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: SaharaColors.gold.withValues(alpha: 0.1)),
                        ),
                        child: Row(children: [
                          _Avatar(initials: initials, size: 44),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: SaharaColors.whiteSoft,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Text('Recepcionista',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: SaharaColors.gold)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: SaharaColors.grayText.withValues(alpha: 0.4),
                              size: 20),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vista de chat — embebida directamente en el tab (sin push)
// ─────────────────────────────────────────────────────────────────────────────

class _ClientChatView extends StatefulWidget {
  final ClientRepository repo;
  final String contactId;
  final String contactName;

  const _ClientChatView({
    required this.repo,
    required this.contactId,
    required this.contactName,
  });

  @override
  State<_ClientChatView> createState() => _ClientChatViewState();
}

class _ClientChatViewState extends State<_ClientChatView> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();

  String? _chatId;
  Stream<List<Map<String, dynamic>>>? _stream;
  bool _initializing = true;
  int  _limit = 20;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _initChat();
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 80) {
      if (_chatId != null) {
        setState(() {
          _limit += 20;
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
      debugPrint('_ClientChatViewState._initChat: $e');
      if (mounted) setState(() => _initializing = false);
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
        content: Text('Error al enviar: $e',
            style: GoogleFonts.inter(color: SaharaColors.whiteSoft)),
        backgroundColor: SaharaColors.grayDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  String get _initials => widget.contactName
      .trim()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: Container(
        decoration: const BoxDecoration(gradient: SaharaGradients.backgroundMain),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMessages()),
              _buildInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: SaharaColors.gold.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          _Avatar(initials: _initials, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.contactName,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        color: SaharaColors.whiteSoft,
                        fontWeight: FontWeight.w600)),
                Text('Recepción · Sahara Club Spa',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: SaharaColors.gold)),
              ],
            ),
          ),
          // Indicador "en línea" (decorativo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF52C41A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF52C41A).withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFF52C41A), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('En línea',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF52C41A),
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_initializing) {
      return const Center(
          child: CircularProgressIndicator(
              color: SaharaColors.gold, strokeWidth: 1.5));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _stream,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: SaharaColors.gold, strokeWidth: 1.5));
        }
        final msgs = snap.data!;
        if (msgs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.waving_hand_outlined,
                      size: 40,
                      color: SaharaColors.gold.withValues(alpha: 0.4)),
                  const SizedBox(height: 14),
                  Text('¡Hola! ¿En qué podemos ayudarte?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: SaharaColors.grayText,
                          height: 1.5)),
                ],
              ),
            ),
          );
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
            return Column(children: [
              if (showDate)
                _DateSeparator(
                    dateStr: msg['created_at'] as String? ?? ''),
              _Bubble(
                msg:  msg,
                mine: (msg['sender_id'] as String?) ==
                    widget.repo.myId,
              ),
            ]);
          },
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
            top: BorderSide(
                color: SaharaColors.gold.withValues(alpha: 0.08))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
              width: 44, height: 44,
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;
  const _Avatar({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SaharaColors.gold.withValues(alpha: 0.12),
        border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.inter(
                fontSize: size * 0.34,
                color: SaharaColors.gold,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool mine;
  const _Bubble({required this.msg, required this.mine});

  @override
  Widget build(BuildContext context) {
    final content = msg['content'] as String? ?? '';
    final ts      = msg['created_at'] as String? ?? '';
    String time   = '';
    try {
      time = DateFormat('HH:mm').format(DateTime.parse(ts).toLocal());
    } catch (_) {}

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            Text(content,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: SaharaColors.whiteSoft,
                    height: 1.4)),
            const SizedBox(height: 3),
            Text(time,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color:
                        SaharaColors.grayText.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final String dateStr;
  const _DateSeparator({required this.dateStr});

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
      child: Row(children: [
        Expanded(
            child: Container(
                height: 0.5,
                color: Colors.white.withValues(alpha: 0.08))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: SaharaColors.grayText.withValues(alpha: 0.6))),
        ),
        Expanded(
            child: Container(
                height: 0.5,
                color: Colors.white.withValues(alpha: 0.08))),
      ]),
    );
  }
}
