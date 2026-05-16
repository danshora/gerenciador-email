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

  // --- MÉTODO ADICIONADO AQUI PARA CORRIGIR O ERRO ---
  Account copyWith({
    String? id,
    String? title,
    String? email,
    String? password,
    String? description,
    int? daysLeft,
    bool? isReady,
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
      'category': category,
      'tags': tags,
      'createdAtMs': createdAt.millisecondsSinceEpoch,
      'updatedAtMs': updatedAt.millisecondsSinceEpoch,
      'expiresAtMs': expiresAt?.millisecondsSinceEpoch,
    };
  }
