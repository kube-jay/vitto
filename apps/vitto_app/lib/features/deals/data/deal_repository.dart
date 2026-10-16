import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/supabase_provider.dart';
import '../../auth/data/session_provider.dart';
import '../domain/deal.dart';
import '../domain/deal_status.dart';

class CheckoutStart {
  const CheckoutStart({
    required this.mode,
    required this.reference,
    this.checkoutUrl,
  });

  final String mode; // mock | sandbox | live
  final String reference;
  final String? checkoutUrl;
}

/// Result of submitting a handover code (wrong codes are counted).
class CodeResult {
  const CodeResult({required this.ok, this.error, this.attemptsLeft});

  final bool ok;
  final String? error;
  final int? attemptsLeft;
}

class DealRepository {
  DealRepository(this._db);

  final SupabaseClient _db;

  Future<List<Deal>> mine() async {
    final rows = await _db
        .from('deals')
        .select(Deal.columns)
        .order('created_at', ascending: false);
    return rows.map(Deal.fromJson).toList();
  }

  Future<Deal?> byId(String id) async {
    final row = await _db
        .from('deals')
        .select(Deal.columns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Deal.fromJson(row);
  }

  Stream<Map<String, dynamic>?> watchRow(String id) => _db
      .from('deals')
      .stream(primaryKey: ['id'])
      .eq('id', id)
      .map((rows) => rows.isEmpty ? null : rows.first);

  Stream<List<Payment>> payments(String dealId) => _db
      .from('payments')
      .stream(primaryKey: ['id'])
      .eq('deal_id', dealId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map(Payment.fromJson).toList());

  Future<Payout?> payout(String dealId) async {
    final row = await _db
        .from('payouts')
        .select('deal_id,status,amount_minor,currency')
        .eq('deal_id', dealId)
        .maybeSingle();
    return row == null ? null : Payout.fromJson(row);
  }

  Future<Set<String>> confirmations(String dealId) async {
    final rows = await _db
        .from('deal_confirmations')
        .select('user_id')
        .eq('deal_id', dealId);
    return {for (final r in rows) r['user_id'] as String};
  }

  Future<void> _call(String fn, Map<String, dynamic> params) =>
      _db.rpc(fn, params: params);

  Future<void> selectMode(String dealId, TransactionType mode) =>
      _call('deal_select_mode', {'p_deal_id': dealId, 'p_mode': mode.wire});

  Future<void> confirmOffline(String dealId) =>
      _call('deal_confirm_offline', {'p_deal_id': dealId});

  Future<({String code, DateTime expiresAt})> handoverCode(
    String dealId,
  ) async {
    final res = await _db.rpc<Map<String, dynamic>>(
      'deal_handover_code',
      params: {'p_deal_id': dealId},
    );
    return (
      code: res['code'] as String,
      expiresAt: DateTime.parse(res['expires_at'] as String),
    );
  }

  Future<CodeResult> confirmOnline(String dealId, String code) async {
    final res = await _db.rpc<Map<String, dynamic>>(
      'deal_confirm_online',
      params: {'p_deal_id': dealId, 'p_code': code},
    );
    return CodeResult(
      ok: res['ok'] == true,
      error: res['error'] as String?,
      attemptsLeft: res['attempts_left'] as int?,
    );
  }

  Future<void> reportConfirmationProblem(String dealId, String? note) => _call(
    'deal_report_confirmation_problem',
    {'p_deal_id': dealId, 'p_note': note},
  );

  Future<void> buyerAnswer(String dealId, bool received, String? note) => _call(
    'deal_buyer_answer',
    {'p_deal_id': dealId, 'p_received': received, 'p_note': note},
  );

  Future<void> raiseDispute(String dealId, String reason, String? details) =>
      _call('deal_raise_dispute', {
        'p_deal_id': dealId,
        'p_reason': reason,
        'p_details': details,
      });

  Future<void> cancel(String dealId, String? reason) =>
      _call('deal_cancel', {'p_deal_id': dealId, 'p_reason': reason});

  // Payments go through Edge Functions; success is decided server-side.
  Future<CheckoutStart> startPayment(String dealId) async {
    final res = await _db.functions.invoke(
      'payment-initialize',
      body: {'deal_id': dealId, 'idempotency_key': const Uuid().v4()},
    );
    final data = (res.data as Map)['data'] as Map;
    return CheckoutStart(
      mode: data['mode'] as String,
      reference: data['reference'] as String,
      checkoutUrl: data['checkout_url'] as String?,
    );
  }

  /// Local/dev only: simulates the provider's verdict (PAYMENT_MODE=mock).
  Future<void> completeMockPayment(String reference, {required bool success}) =>
      _db.functions.invoke(
        'payment-mock-complete',
        body: {
          'reference': reference,
          'outcome': success ? 'successful' : 'failed',
        },
      );

  Future<void> reconcile(String dealId) =>
      _db.functions.invoke('payment-reconcile', body: {'deal_id': dealId});
}

final dealRepositoryProvider = Provider(
  (ref) => DealRepository(ref.watch(supabaseProvider)),
);

final myDealsProvider = FutureProvider.autoDispose<List<Deal>>((ref) async {
  if (ref.watch(currentUserIdProvider) == null) return const [];
  return ref.watch(dealRepositoryProvider).mine();
});

/// Deal with joins, refreshed live from realtime row updates.
final dealProvider = StreamProvider.autoDispose.family<Deal?, String>((
  ref,
  id,
) async* {
  final repo = ref.watch(dealRepositoryProvider);
  var deal = await repo.byId(id);
  yield deal;
  if (deal == null) return;
  await for (final row in repo.watchRow(id)) {
    if (row != null) {
      deal = deal!.mergeRow(row);
      yield deal;
    }
  }
});

final dealPaymentsProvider = StreamProvider.autoDispose
    .family<List<Payment>, String>(
      (ref, id) => ref.watch(dealRepositoryProvider).payments(id),
    );

final dealPayoutProvider = FutureProvider.autoDispose.family<Payout?, String>(
  (ref, id) => ref.watch(dealRepositoryProvider).payout(id),
);

final dealConfirmationsProvider = FutureProvider.autoDispose
    .family<Set<String>, String>(
      (ref, id) => ref.watch(dealRepositoryProvider).confirmations(id),
    );
