import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientRepository {
  final _db = Supabase.instance.client;

  String get myId => _db.auth.currentUser!.id;

  // Devuelve las recepcionistas activas — son el único contacto permitido
  // para los clientes desde la app.
  Future<List<Map<String, dynamic>>> getReceptionists() async {
    try {
      final raw = await _db
          .from('profiles')
          .select('id, full_name, avatar_url')
          .inFilter('role', ['receptionist', 'admin'])
          .not('is_active', 'eq', false)
          .order('full_name');
      return (raw as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ClientRepository.getReceptionists: $e');
      return [];
    }
  }

  Future<String> getOrCreateChat(String otherUserId) async {
    final me = myId;
    final existing = await _db
        .from('chats')
        .select('id')
        .or('and(participant_1.eq.$me,participant_2.eq.$otherUserId),'
            'and(participant_1.eq.$otherUserId,participant_2.eq.$me)')
        .maybeSingle();
    if (existing != null) return existing['id'] as String;
    final created = await _db
        .from('chats')
        .insert({'participant_1': me, 'participant_2': otherUserId})
        .select('id')
        .single();
    return created['id'] as String;
  }

  Stream<List<Map<String, dynamic>>> streamMessages(
      String chatId, {int limit = 20}) {
    return _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((list) => list.cast<Map<String, dynamic>>());
  }

  Future<void> sendMessage(String chatId, String content) async {
    await _db.from('messages').insert({
      'chat_id':   chatId,
      'sender_id': myId,
      'content':   content,
    });
  }
}
