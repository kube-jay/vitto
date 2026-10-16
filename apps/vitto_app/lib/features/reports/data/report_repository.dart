import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/supabase_provider.dart';

const reportReasons = [
  'prohibited_item',
  'scam',
  'offensive',
  'wrong_info',
  'no_show',
  'item_not_received',
  'other',
];

class Report {
  const Report({
    required this.id,
    required this.reporterId,
    required this.targetKind,
    required this.targetId,
    required this.reason,
    required this.details,
    required this.status,
    required this.createdAt,
    this.resolutionNote,
  });

  final String id;
  final String reporterId;
  final String targetKind;
  final String targetId;
  final String reason;
  final String details;
  final String status;
  final DateTime createdAt;
  final String? resolutionNote;

  factory Report.fromJson(Map<String, dynamic> j) => Report(
    id: j['id'] as String,
    reporterId: j['reporter_id'] as String,
    targetKind: j['target_kind'] as String,
    targetId: j['target_id'] as String,
    reason: j['reason'] as String,
    details: (j['details'] as String?) ?? '',
    status: j['status'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    resolutionNote: j['resolution_note'] as String?,
  );
}

class EvidenceFile {
  const EvidenceFile({
    required this.path,
    required this.uploaderId,
    this.note,
    required this.createdAt,
  });

  final String path;
  final String uploaderId;
  final String? note;
  final DateTime createdAt;
}

class ReportRepository {
  ReportRepository(this._db);

  final SupabaseClient _db;

  Future<void> create({
    required String targetKind,
    required String targetId,
    required String reason,
    required String details,
  }) => _db.from('reports').insert({
    'target_kind': targetKind,
    'target_id': targetId,
    'reason': reason,
    'details': details,
  });

  /// Admins see every report through RLS; users only their own.
  Future<List<Report>> list({String? status}) async {
    var q = _db.from('reports').select();
    if (status != null) q = q.eq('status', status);
    final rows = await q.order('created_at', ascending: false).limit(200);
    return rows.map(Report.fromJson).toList();
  }

  Future<List<EvidenceFile>> evidence(String dealId) async {
    final rows = await _db
        .from('dispute_evidence')
        .select()
        .eq('deal_id', dealId)
        .order('created_at', ascending: true);
    return [
      for (final r in rows)
        EvidenceFile(
          path: r['storage_path'] as String,
          uploaderId: r['uploader_id'] as String,
          note: r['note'] as String?,
          createdAt: DateTime.parse(r['created_at'] as String),
        ),
    ];
  }

  Future<void> addEvidence({
    required String dealId,
    required String uid,
    required Uint8List bytes,
    required String mime,
    String? note,
  }) async {
    final ext = switch (mime) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'application/pdf' => 'pdf',
      _ => 'jpg',
    };
    final path = '$dealId/$uid/${const Uuid().v4()}.$ext';
    await _db.storage
        .from('dispute-evidence')
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
    await _db.from('dispute_evidence').insert({
      'deal_id': dealId,
      'storage_path': path,
      'note': note,
    });
  }

  /// Private bucket: short-lived signed links only.
  Future<String> evidenceUrl(String path) =>
      _db.storage.from('dispute-evidence').createSignedUrl(path, 300);
}

final reportRepositoryProvider = Provider(
  (ref) => ReportRepository(ref.watch(supabaseProvider)),
);

final myReportsProvider = FutureProvider.autoDispose<List<Report>>(
  (ref) => ref.watch(reportRepositoryProvider).list(),
);

final dealEvidenceProvider = FutureProvider.autoDispose
    .family<List<EvidenceFile>, String>(
      (ref, id) => ref.watch(reportRepositoryProvider).evidence(id),
    );
