import 'dart:convert';
import 'package:uuid/uuid.dart';

class Account {
  final String id;
  String title;
  String email;
  String password;
  String description;
  int daysLeft;
  bool isReady;
  String category;
  List<String> tags;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? expiresAt;

  Account({
    String? id,
    required this.title,
    required this.email,
    required this.password,
    this.description = '',
    this.daysLeft = 0,
    this.isReady = true,
    this.category = 'Outros',
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.expiresAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = (tags == null || tags.isEmpty) ? [category] : List<String>.from(tags),
        id = id ?? const Uuid().v4();

  /// Retorna quanto tempo falta até expirar (ou Duration.zero se já expirou).
  Duration remaining(DateTime now) {
    final end = expiresAt;
    if (end == null) return Duration(days: daysLeft);
    final diff = end.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'email': email,
      'password': password,
      'description': description,
      'daysLeft': daysLeft,
      'isReady': isReady,
      'category': category,
      'tags': tags,
      'createdAtMs': createdAt.millisecondsSinceEpoch,
      'updatedAtMs': updatedAt.millisecondsSinceEpoch,
      'expiresAtMs': expiresAt?.millisecondsSinceEpoch,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    final createdAtMs = map['createdAtMs'];
    final updatedAtMs = map['updatedAtMs'];
    final expiresAtMs = map['expiresAtMs'];

    DateTime safeDate(dynamic ms, DateTime fallback) {
      if (ms is int) return DateTime.fromMillisecondsSinceEpoch(ms);
      if (ms is String) {
        final parsed = int.tryParse(ms);
        if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed);
      }
      return fallback;
    }

    final createdAt = safeDate(createdAtMs, now);
    final updatedAt = safeDate(updatedAtMs, createdAt);
    final int legacyDays = (map['daysLeft'] is int) ? (map['daysLeft'] as int) : int.tryParse('${map['daysLeft']}') ?? 0;
    final String legacyCategory = (map['category'] ?? 'Outros').toString();

    List<String> parseTags(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
      }
      if (raw is String && raw.trim().isNotEmpty) {
        // Aceita formato antigo onde alguém possa ter salvo como string única.
        return [raw.trim()];
      }
      return [legacyCategory];
    }

    final tags = parseTags(map['tags']);
    DateTime? expiresAt;
    if (expiresAtMs != null) {
      expiresAt = safeDate(expiresAtMs, now);
    } else if (legacyDays > 0) {
      // Migração automática: se já existia daysLeft, vira um contador por tempo.
      expiresAt = createdAt.add(Duration(days: legacyDays));
    }

    return Account(
      id: map['id'],
      title: map['title'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      description: map['description'] ?? '',
      daysLeft: legacyDays,
      isReady: map['isReady'] ?? true,
      category: legacyCategory,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
      expiresAt: expiresAt,
    );
  }

  String toJson() => json.encode(toMap());

  factory Account.fromJson(String source) => Account.fromMap(json.decode(source));
}
