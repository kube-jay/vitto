import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../../auth/data/session_provider.dart';
import '../domain/conversation.dart';

class ConversationRepository {
  ConversationRepository(this._db);

  final SupabaseClient _db;

  Future<List<Conversation>> inbox(String uid) async {
    final rows = await _db
        .from('conversations')
        .select(Conversation.columns)
        .order('last_message_at', ascending: false);
    return [for (final r in rows) Conversation.fromJson(r, myId: uid)];
  }

  Future<Conversation?> byId(String id, String uid) async {
    final row = await _db
        .from('conversations')
        .select(Conversation.columns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Conversation.fromJson(row, myId: uid);
  }

  /// Opens (or reuses) the buyer's Conversation about a Listing.
  Future<String> start(String listingId) async => await _db.rpc<String>(
    'start_conversation',
    params: {'p_listing_id': listingId},
  );

  /// Realtime messages; RLS limits the stream to participants (AT-04).
  Stream<List<Message>> messages(String conversationId) => _db
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map(Message.fromJson).toList());

  Future<void> send(String conversationId, String body) => _db
      .from('messages')
      .insert({'conversation_id': conversationId, 'body': body.trim()});

  Future<void> markRead(String conversationId) =>
      _db.from('conversation_reads').upsert({
        'conversation_id': conversationId,
        'last_read_at': DateTime.now().toUtc().toIso8601String(),
      });
}

final conversationRepositoryProvider = Provider(
  (ref) => ConversationRepository(ref.watch(supabaseProvider)),
);

final inboxProvider = FutureProvider.autoDispose<List<Conversation>>((
  ref,
) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const [];
  return ref.watch(conversationRepositoryProvider).inbox(uid);
});

final conversationProvider = FutureProvider.autoDispose
    .family<Conversation?, String>((ref, id) async {
      final uid = ref.watch(currentUserIdProvider);
      if (uid == null) return null;
      return ref.watch(conversationRepositoryProvider).byId(id, uid);
    });

final messagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>(
      (ref, id) => ref.watch(conversationRepositoryProvider).messages(id),
    );

final unreadCountProvider = Provider.autoDispose<int>(
  (ref) =>
      ref.watch(inboxProvider).value?.where((c) => c.hasUnread).length ?? 0,
);
