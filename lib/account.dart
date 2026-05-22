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
  bool isFavorite;
  bool hasExpiration; // NOVO: Controle de conta vitalícia
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
    this.isFavorite = false,
    this.hasExpiration = true, 
    String category = 'Outros',
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.expiresAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        category = category.isEmpty ? 'Outros' : category,
        tags = tags != null ? List<String>.from(tags) : [],
        id = id ?? const Uuid().v4();

  Duration remaining(DateTime now) {
    if (!hasExpiration) return const Duration(days: 9999); // Simula infinito
    final end = expiresAt;
    if (end == null) return Duration(days: daysLeft);
    final diff = end.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  Account copyWith({
    String? id,
    String? title,
    String? email,
    String? password,
    String? description,
    int? daysLeft,
    bool? isReady,
    bool? isFavorite,
    bool? hasExpiration,
    String? category,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return Account(
      id: id ?? this.id,
      title: title ?? this.title,
      email: email ?? this.email,
      password: password ?? this.password,
      description: description ?? this.description,
      daysLeft: daysLeft ?? this.daysLeft,
      isReady: isReady ?? this.isReady,
      isFavorite: isFavorite ?? this.isFavorite,
      hasExpiration: hasExpiration ?? this.hasExpiration,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
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
      'isFavorite': isFavorite,
      'hasExpiration': hasExpiration,
      'category': category,
      'tags': tags,
      'createdAtMs': createdAt.millisecondsSinceEpoch,
      'updatedAtMs': updatedAt.millisecondsSinceEpoch,
      'expiresAtMs': expiresAt?.millisecondsSinceEpoch,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    DateTime safeDate(dynamic ms, DateTime fallback) {
      if (ms is int) return DateTime.fromMillisecondsSinceEpoch(ms);
      if (ms is String) {
        final parsed = int.tryParse(ms);
        if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed);
      }
      return fallback;
    }

    final createdAt = safeDate(map['createdAtMs'], now);
    List<String> parseTags(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
      return [];
    }

    return Account(
      id: map['id'],
      title: map['title'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      description: map['description'] ?? '',
      daysLeft: map['daysLeft'] is int ? map['daysLeft'] : 0,
      isReady: map['isReady'] ?? true,
      isFavorite: map['isFavorite'] ?? false,
      hasExpiration: map['hasExpiration'] ?? true, // Contas antigas terão expiração por padrão
      category: map['category'] ?? 'Outros',
      tags: parseTags(map['tags']),
      createdAt: createdAt,
      updatedAt: safeDate(map['updatedAtMs'], createdAt),
      expiresAt: map['expiresAtMs'] != null ? safeDate(map['expiresAtMs'], now) : null,
    );
  }

  String toJson() => json.encode(toMap());
  factory Account.fromJson(String source) => Account.fromMap(json.decode(source));
}
