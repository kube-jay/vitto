import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../../deals/domain/deal.dart';
import '../../listings/domain/listing.dart';

class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.countryCode,
    this.city,
    required this.joinedAt,
    this.suspendedAt,
    required this.completedDeals,
    required this.isAdmin,
  });

  final String id;
  final String email;
  final String displayName;
  final String countryCode;
  final String? city;
  final DateTime joinedAt;
  final DateTime? suspendedAt;
  final int completedDeals;
  final bool isAdmin;

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
    id: j['id'] as String,
    email: (j['email'] as String?) ?? '',
    displayName: j['display_name'] as String,
    countryCode: j['country_code'] as String,
    city: j['city'] as String?,
    joinedAt: DateTime.parse(j['joined_at'] as String),
    suspendedAt: j['suspended_at'] == null
        ? null
        : DateTime.parse(j['suspended_at'] as String),
    completedDeals: (j['completed_deals_count'] as int?) ?? 0,
    isAdmin: j['is_admin'] == true,
  );
}

class PayoutRow {
  const PayoutRow({
    required this.dealId,
    required this.status,
    required this.amountMinor,
    required this.currency,
    this.lastError,
  });

  final String dealId;
  final String status;
  final int amountMinor;
  final String currency;
  final String? lastError;
}

/// Admin operations (Part I §18). Every call is re-checked and audited on
/// the server; hiding admin screens in the UI is not the security boundary.
class AdminRepository {
  AdminRepository(this._db);

  final SupabaseClient _db;

  Future<List<AdminUser>> users(String query) async {
    final rows = await _db.rpc<List<dynamic>>(
      'admin_list_users',
      params: {'p_query': query},
    );
    return rows.cast<Map<String, dynamic>>().map(AdminUser.fromJson).toList();
  }

  Future<void> setUserSuspension(String id, bool suspend, String reason) =>
      _db.rpc(
        'admin_set_user_suspension',
        params: {'p_user_id': id, 'p_suspend': suspend, 'p_reason': reason},
      );

  Future<List<Listing>> listings(String? status) async {
    var q = _db.from('listings').select(Listing.columns);
    if (status != null) q = q.eq('status', status);
    final rows = await q.order('created_at', ascending: false).limit(200);
    return rows.map(Listing.fromJson).toList();
  }

  Future<void> setListingSuspension(String id, bool suspend, String reason) =>
      _db.rpc(
        'admin_set_listing_suspension',
        params: {'p_listing_id': id, 'p_suspend': suspend, 'p_reason': reason},
      );

  Future<List<Category>> allCategories() async {
    final rows = await _db
        .from('categories')
        .select(Category.columns)
        .order('sort_order', ascending: true);
    return rows.map(Category.fromJson).toList();
  }

  Future<void> saveCategory({
    String? id,
    required String slug,
    required String nameEn,
    required String nameFr,
    required int sortOrder,
    required bool active,
  }) async {
    final data = {
      'slug': slug,
      'name_en': nameEn,
      'name_fr': nameFr,
      'sort_order': sortOrder,
      'active': active,
    };
    if (id == null) {
      await _db.from('categories').insert(data);
    } else {
      await _db.from('categories').update(data).eq('id', id);
    }
  }

  Future<void> updateReport(String id, String status, String note) => _db.rpc(
    'admin_update_report',
    params: {'p_report_id': id, 'p_status': status, 'p_note': note},
  );

  Future<List<Deal>> disputedDeals() async {
    final rows = await _db
        .from('deals')
        .select(Deal.columns)
        .eq('status', 'disputed')
        .order('updated_at', ascending: false);
    return rows.map(Deal.fromJson).toList();
  }

  Future<void> resolveDispute(String dealId, String disposition, String note) =>
      _db.rpc(
        'admin_resolve_dispute',
        params: {
          'p_deal_id': dealId,
          'p_disposition': disposition,
          'p_note': note,
        },
      );

  Future<List<PayoutRow>> payouts() async {
    final rows = await _db
        .from('payouts')
        .select('deal_id,status,amount_minor,currency,last_error')
        .order('updated_at', ascending: false)
        .limit(200);
    return [
      for (final r in rows)
        PayoutRow(
          dealId: r['deal_id'] as String,
          status: r['status'] as String,
          amountMinor: (r['amount_minor'] as num).toInt(),
          currency: r['currency'] as String,
          lastError: r['last_error'] as String?,
        ),
    ];
  }

  Future<List<Payment>> payments() async {
    final rows = await _db
        .from('payments')
        .select(Payment.columns)
        .order('created_at', ascending: false)
        .limit(200);
    return rows.map(Payment.fromJson).toList();
  }

  Future<void> releasePayout(String dealId) =>
      _db.functions.invoke('payout-request', body: {'deal_id': dealId});
}

final adminRepositoryProvider = Provider(
  (ref) => AdminRepository(ref.watch(supabaseProvider)),
);
