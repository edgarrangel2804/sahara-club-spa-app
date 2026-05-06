import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahara_club_spa_app/core/theme.dart';
import 'package:sahara_club_spa_app/features/reception/data/reception_repository.dart';

class AddClientDialog extends StatefulWidget {
  final ReceptionRepository repo;
  final void Function(Map<String, dynamic> newClient) onCreated;

  const AddClientDialog({
    super.key,
    required this.repo,
    required this.onCreated,
  });

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  bool    _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _submitting = true; _error = null; });
    try {
      final client = await widget.repo.createClient(
        fullName: _nameCtrl.text,
        phone:    _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
        email:    _emailCtrl.text.isEmpty ? null : _emailCtrl.text,
      );
      widget.onCreated(client);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding:   const EdgeInsets.fromLTRB(28, 28, 28, 0),
      contentPadding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      actionsPadding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      title: Text('Nuevo Cliente', style: GoogleFonts.playfairDisplay(
          fontSize: 22, color: SaharaColors.gold)),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              _field(
                controller: _nameCtrl,
                hint: 'Nombre completo',
                icon: Icons.person_outline_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'El nombre es requerido' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _phoneCtrl,
                hint: 'Teléfono (opcional)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _emailCtrl,
                hint: 'Email (opcional)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Text(_error!, style: const TextStyle(
                      color: Colors.red, fontSize: 12)),
                ),
              ],
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: SaharaColors.gold,
            foregroundColor: Colors.black,
            disabledBackgroundColor: SaharaColors.gold.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2))
              : const Text('Crear Cliente',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller:          controller,
      validator:           validator,
      keyboardType:        keyboardType,
      textCapitalization:  textCapitalization,
      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
        prefixIcon: Icon(icon, size: 18, color: SaharaColors.grayText),
        filled:          true,
        fillColor:       const Color(0xFF1A1A1A),
        contentPadding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SaharaColors.grayDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SaharaColors.grayDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SaharaColors.gold, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
      ),
    );
  }
}
