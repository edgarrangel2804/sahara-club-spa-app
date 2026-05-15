import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/data/services/auth_service.dart';

class ReceptionQrScannerPage extends StatefulWidget {
  const ReceptionQrScannerPage({super.key});

  @override
  State<ReceptionQrScannerPage> createState() => _ReceptionQrScannerPageState();
}

class _ReceptionQrScannerPageState extends State<ReceptionQrScannerPage> {
  final _textCtrl    = TextEditingController();
  final _focusNode   = FocusNode();
  bool _cameraMode   = false;
  bool _loading      = false;
  MobileScannerController? _cameraCtrl;

  // UUID pattern
  static final _uuidRe = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    _cameraCtrl?.dispose();
    super.dispose();
  }

  void _toggleCamera() {
    setState(() {
      _cameraMode = !_cameraMode;
      if (_cameraMode) {
        _cameraCtrl = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
      } else {
        _cameraCtrl?.dispose();
        _cameraCtrl = null;
        WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
      }
    });
  }

  void _onFieldChanged(String val) {
    if (_uuidRe.hasMatch(val.trim())) {
      _validate(val.trim());
    }
  }

  void _onFieldSubmitted(String val) {
    final v = val.trim();
    if (v.isNotEmpty) _validate(v);
  }

  void _onQrDetected(BarcodeCapture capture) {
    final raw = capture.barcodes.firstOrNull?.rawValue ?? '';
    if (raw.isNotEmpty) {
      _cameraCtrl?.stop();
      setState(() => _cameraMode = false);
      _validate(raw.trim());
    }
  }

  Future<void> _validate(String itemId) async {
    if (_loading) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    _textCtrl.clear();

    try {
      final staffId = AuthService().currentUser?.id;
      final resp = await Supabase.instance.client.functions.invoke(
        'validate-qr',
        body: {
          'order_item_id': itemId,
          'staff_id': staffId,
          'action': 'validate',
        },
      );

      final data = (resp.data as Map<String, dynamic>?) ?? {};

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _QrResultPage(
            itemId: itemId,
            data: data,
            staffId: staffId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error de conexión', style: GoogleFonts.inter(
            fontSize: 13, color: SaharaColors.whiteSoft)),
          backgroundColor: const Color(0xFF1A0A0A),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _loading
                  ? _buildLoading()
                  : _cameraMode
                      ? _buildCamera()
                      : _buildGunInput(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: Row(
        children: [
          Text('ESCANEAR QR', style: GoogleFonts.inter(
            fontSize: 11, color: SaharaColors.gold,
            letterSpacing: 3, fontWeight: FontWeight.w700,
          )),
          const Spacer(),
          GestureDetector(
            onTap: _toggleCamera,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _cameraMode
                    ? SaharaColors.gold.withValues(alpha: 0.15)
                    : SaharaColors.grayDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _cameraMode
                      ? SaharaColors.gold.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _cameraMode ? Icons.keyboard_outlined : Icons.camera_alt_outlined,
                    size: 15,
                    color: _cameraMode ? SaharaColors.gold : SaharaColors.grayText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _cameraMode ? 'Usar pistola' : 'Usar cámara',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _cameraMode ? SaharaColors.gold : SaharaColors.grayText,
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

  Widget _buildGunInput() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Visual de pistola lectora
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: SaharaColors.gold.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: SaharaColors.gold.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded,
                color: SaharaColors.gold, size: 36),
          ),
          const SizedBox(height: 24),
          Text('Listo para escanear', style: GoogleFonts.playfairDisplay(
            fontSize: 22, color: SaharaColors.whiteSoft, fontWeight: FontWeight.w300,
          )),
          const SizedBox(height: 8),
          Text(
            'Apunta la pistola lectora al código QR\ndel cliente. El sistema valida automáticamente.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13, color: SaharaColors.grayText,
              height: 1.65, fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 40),
          // Campo invisible donde la pistola escribe
          Opacity(
            opacity: 0.0,
            child: SizedBox(
              height: 1,
              child: TextField(
                controller: _textCtrl,
                focusNode: _focusNode,
                onChanged: _onFieldChanged,
                onSubmitted: _onFieldSubmitted,
                autofocus: true,
              ),
            ),
          ),
          // Indicador de campo activo
          AnimatedBuilder(
            animation: _focusNode,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? SaharaColors.gold.withValues(alpha: 0.4)
                      : SaharaColors.grayDark,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: _focusNode.hasFocus
                          ? const Color(0xFF4CAF50)
                          : SaharaColors.grayDark,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _focusNode.hasFocus ? 'Campo activo — escanea el QR' : 'Toca para activar',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _focusNode.hasFocus
                          ? SaharaColors.whiteSoft
                          : SaharaColors.grayText.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            child: Text('Toca aquí si se pierde el foco', style: GoogleFonts.inter(
              fontSize: 11, color: SaharaColors.grayText.withValues(alpha: 0.4),
              decoration: TextDecoration.underline,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildCamera() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Stack(
        children: [
          MobileScanner(
            controller: _cameraCtrl!,
            onDetect: _onQrDetected,
          ),
          // Overlay con visor
          Center(
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: SaharaColors.gold, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: Text('Apunta al código QR del ticket',
                  style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.white,
                    shadows: [const Shadow(blurRadius: 8)],
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: SaharaColors.gold, strokeWidth: 1.5),
          const SizedBox(height: 20),
          Text('Validando código…', style: GoogleFonts.inter(
            fontSize: 14, color: SaharaColors.grayText,
          )),
        ],
      ),
    );
  }
}

// ── Resultado de la validación ────────────────────────────────────────────────

class _QrResultPage extends StatefulWidget {
  const _QrResultPage({
    required this.itemId,
    required this.data,
    required this.staffId,
  });
  final String itemId;
  final Map<String, dynamic> data;
  final String? staffId;

  @override
  State<_QrResultPage> createState() => _QrResultPageState();
}

class _QrResultPageState extends State<_QrResultPage> {
  bool _redeeming = false;
  bool _redeemed  = false;

  bool get _valid           => widget.data['valid'] == true;
  bool get _alreadyRedeemed => widget.data['already_redeemed'] == true;

  Map<String, dynamic> get _item =>
      (widget.data['item'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _order =>
      (widget.data['order'] as Map<String, dynamic>?) ?? {};

  Future<void> _redeem() async {
    setState(() => _redeeming = true);
    HapticFeedback.mediumImpact();
    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'validate-qr',
        body: {
          'order_item_id': widget.itemId,
          'staff_id': widget.staffId,
          'action': 'redeem',
        },
      );
      final data = (resp.data as Map<String, dynamic>?) ?? {};
      if (data['redeemed'] == true) {
        setState(() => _redeemed = true);
        HapticFeedback.heavyImpact();
      }
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName  = _item['product_name'] as String? ?? '';
    final customerName = _order['customer_name'] as String? ?? '';
    final customerEmail= _order['customer_email'] as String? ?? '';
    final price        = (_item['unit_price'] as num?)?.toDouble() ?? 0;

    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;
    final String statusSub;

    if (_redeemed) {
      statusColor = const Color(0xFF4CAF50);
      statusIcon  = Icons.check_circle_rounded;
      statusLabel = '¡Canjeado!';
      statusSub   = 'Acceso autorizado.';
    } else if (_alreadyRedeemed) {
      statusColor = Colors.red;
      statusIcon  = Icons.cancel_rounded;
      statusLabel = 'Ya canjeado';
      statusSub   = 'Este ticket ya fue utilizado.';
    } else if (_valid) {
      statusColor = SaharaColors.gold;
      statusIcon  = Icons.verified_rounded;
      statusLabel = 'Ticket válido';
      statusSub   = 'Listo para canjear.';
    } else {
      statusColor = Colors.red;
      statusIcon  = Icons.error_rounded;
      statusLabel = 'No válido';
      statusSub   = widget.data['error'] as String? ?? 'Código inválido.';
    }

    return Scaffold(
      backgroundColor: SaharaColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: SaharaColors.grayDark, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 15),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Resultado', style: GoogleFonts.playfairDisplay(
                    fontSize: 20, color: SaharaColors.whiteSoft,
                    fontWeight: FontWeight.w300,
                  )),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Status icon
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 38),
                    ),
                    const SizedBox(height: 20),
                    Text(statusLabel, style: GoogleFonts.playfairDisplay(
                      fontSize: 26, color: statusColor, fontWeight: FontWeight.w300,
                    )),
                    const SizedBox(height: 6),
                    Text(statusSub, style: GoogleFonts.inter(
                      fontSize: 13, color: SaharaColors.grayText, height: 1.5,
                    )),
                    const SizedBox(height: 32),

                    // Info card
                    if (productName.isNotEmpty || customerName.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (productName.isNotEmpty) ...[
                              Text('PRODUCTO', style: GoogleFonts.inter(
                                fontSize: 9, color: SaharaColors.grayText.withValues(alpha: 0.5),
                                letterSpacing: 2,
                              )),
                              const SizedBox(height: 4),
                              Text(productName, style: GoogleFonts.playfairDisplay(
                                fontSize: 18, color: SaharaColors.whiteSoft,
                                fontWeight: FontWeight.w400,
                              )),
                              const SizedBox(height: 16),
                            ],
                            if (customerName.isNotEmpty) ...[
                              Text('CLIENTE', style: GoogleFonts.inter(
                                fontSize: 9, color: SaharaColors.grayText.withValues(alpha: 0.5),
                                letterSpacing: 2,
                              )),
                              const SizedBox(height: 4),
                              Text(customerName, style: GoogleFonts.inter(
                                fontSize: 14, color: SaharaColors.whiteSoft,
                              )),
                              if (customerEmail.isNotEmpty)
                                Text(customerEmail, style: GoogleFonts.inter(
                                  fontSize: 12, color: SaharaColors.grayText,
                                  fontWeight: FontWeight.w300,
                                )),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('MONTO', style: GoogleFonts.inter(
                                  fontSize: 9, color: SaharaColors.grayText.withValues(alpha: 0.5),
                                  letterSpacing: 2,
                                )),
                                Text(
                                  price == 0 ? 'Incluido' : '\$${price.toStringAsFixed(0)} MXN',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 16, color: SaharaColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),

                    // CTA
                    if (_valid && !_alreadyRedeemed && !_redeemed)
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: SaharaGradients.goldShimmer,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(
                              color: SaharaColors.gold.withValues(alpha: 0.25),
                              blurRadius: 16, offset: const Offset(0, 4),
                            )],
                          ),
                          child: ElevatedButton(
                            onPressed: _redeeming ? null : _redeem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: SaharaColors.black,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              textStyle: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _redeeming
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: SaharaColors.black))
                                : const Text('Marcar como canjeado'),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SaharaColors.grayText,
                            side: BorderSide(color: SaharaColors.grayDark),
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            textStyle: GoogleFonts.inter(fontSize: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Volver al escáner'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
