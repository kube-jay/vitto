import '../../profile/domain/profile.dart';

/// 1–5 star Rating tied to a completed Deal (Part I §16).
class Rating {
  const Rating({
    required this.id,
    required this.dealId,
    required this.authorId,
    required this.recipientId,
    required this.stars,
    this.comment,
    required this.createdAt,
    this.author,
  });

  final String id;
  final String dealId;
  final String authorId;
  final String recipientId;
  final int stars;
  final String? comment;
  final DateTime createdAt;
  final Profile? author;

  static const columns =
      'id,deal_id,author_id,recipient_id,stars,comment,created_at,'
      'author:profiles!ratings_author_id_fkey(${Profile.columns})';

  factory Rating.fromJson(Map<String, dynamic> j) => Rating(
    id: j['id'] as String,
    dealId: j['deal_id'] as String,
    authorId: j['author_id'] as String,
    recipientId: j['recipient_id'] as String,
    stars: (j['stars'] as num).toInt(),
    comment: j['comment'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    author: j['author'] is Map<String, dynamic>
        ? Profile.fromJson(j['author'] as Map<String, dynamic>)
        : null,
  );
}
