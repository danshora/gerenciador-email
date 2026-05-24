import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as enc;

import 'account.dart';

class AccountManager extends ChangeNotifier {
  static const String _storageKey = 'vaporwave_atomic_vault.json';
  static const String _tagsKey = 'vaporwave_atomic_tags.json';
  static const String _premiumKey = 'vaporwave_premium_atomic';

  final _iv = enc.IV.fromLength(16);
  final enc.Key _masterKey = enc.Key.fromUtf8('VaporManagerStaticMasterKey32Bit');

  List<Account> _accounts = [];
  List<String> _savedTags = [];
  bool _isLoading = true;
  bool _isPremium = false;
  String? _appDirPath;

  List<Account> get accounts {
    final favs = _accounts.where((a) => a.isFavorite).toList();
    final nonFavs = _accounts.where((a) => !a.isFavorite).toList();
    return [...favs, ...nonFavs];
  }

  List<String> get savedTags => _savedTags;
  bool get isLoading => _isLoading;
  bool get isPremium => _isPremium;

  AccountManager() {
    _initSystem();
  }

  // ==========================================================
  // 🛡️ TRADUTORES SEGUROS (Evita crashes invisíveis por datas)
  // ==========================================================
  Map<String, dynamic> _safeToMap(Account a) {
    return {
      'id': a.id,
      'title': a.title,
      'email': a.email,
      'password': a.password,
      'description': a.description,
      'daysLeft': a.daysLeft,
      'isReady': a.isReady,
      'isFavorite': a.isFavorite,
      'hasExpiration': a.hasExpiration,
      'category': a.category,
      'tags': a.tags.toList(),
      'createdAt': a.createdAt.toIso8601String(),
      'updatedAt': a.updatedAt.toIso8601String(),
      'expiresAt': a.expiresAt?.toIso8601String(),
    };
  }

  Account _safeFromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      daysLeft: int.tryParse(map['daysLeft']?.toString() ?? '0') ?? 0,
      isReady: map['isReady'] == true,
      isFavorite: map['isFavorite'] == true,
      hasExpiration: map['hasExpiration'] == true,
      category: map['category']?.toString() ?? '',
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
      expiresAt: map['expiresAt'] != null ? DateTime.tryParse(map['expiresAt'].toString()) : null,
    );
  }

  // ==========================================================
  // 🚀 INICIALIZAÇÃO DO SISTEMA
  // ==========================================================
  Future<void> _initSystem() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _appDirPath = dir.path;

      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;

      _loadDataSync();
    } catch (e) {
      debugPrint('Erro de Inicialização: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================================
  // 🔒 LEITURA E ESCRITA ATÓMICA SÍNCRONA (A Prova de Falhas)
  // ==========================================================
  void _loadDataSync() {
    if (_appDirPath == null) return;
    final encrypter = enc.Encrypter(enc.AES(_masterKey));

    try {
      final file = File('$_appDirPath/$_storageKey');
      if (file.existsSync()) {
        final encryptedData = file.readAsStringSync();
        if (encryptedData.isNotEmpty) {
          final jsonString = encrypter.decrypt64(encryptedData, iv: _iv);
          final List<dynamic> decodedList = json.decode(jsonString);
          final List<Account> loadedAccounts = [];
          for (var item in decodedList) {
            if (item is Map<String, dynamic>) {
              try { loadedAccounts.add(_safeFromMap(item)); } catch (_) {}
            }
          }
          _accounts = loadedAccounts;
        }
      }
    } catch (e) { debugPrint('Erro na leitura de contas'); }

    try {
      final file = File('$_appDirPath/$_tagsKey');
      if (file.existsSync()) {
        final encryptedData = file.readAsStringSync();
        if (encryptedData.isNotEmpty) {
          final jsonString = encrypter.decrypt64(encryptedData, iv: _iv);
          _savedTags = List<String>.from(json.decode(jsonString));
        }
      }
    } catch (e) { debugPrint('Erro na leitura de tags'); }
  }

  void _saveAccountsSync() {
    if (_appDirPath == null) return;
    try {
      final encrypter = enc.Encrypter(enc.AES(_masterKey));
      final mapList = _accounts.map((a) => _safeToMap(a)).toList();
      final String encryptedData = encrypter.encrypt(json.encode(mapList), iv: _iv).base64;

      final tempFile = File('$_appDirPath/$_storageKey.temp');
      final finalFile = File('$_appDirPath/$_storageKey');

      // 1. Grava no ficheiro temporário e obriga o hardware a escrever imediatamente
      tempFile.writeAsStringSync(encryptedData, flush: true);
      // 2. Renomeia instantaneamente (Operação Atómica impossível de ser corrompida)
      tempFile.renameSync(finalFile.path);
    } catch (e) {
      debugPrint('Erro no salvamento atómico de contas');
    }
  }

  void _saveTagsSync() {
    if (_appDirPath == null) return;
    try {
      final encrypter = enc.Encrypter(enc.AES(_masterKey));
      final String encryptedData = encrypter.encrypt(json.encode(_savedTags), iv: _iv).base64;

      final tempFile = File('$_appDirPath/$_tagsKey.temp');
      final finalFile = File('$_appDirPath/$_tagsKey');

      tempFile.writeAsStringSync(encryptedData, flush: true);
      tempFile.renameSync(finalFile.path);
    } catch (e) {
      debugPrint('Erro no salvamento atómico de tags');
    }
  }

  // ==========================================================
  // 🛠️ MÉTODOS DE NEGÓCIO
  // ==========================================================

  Future<void> togglePremium() async {
    _isPremium = !_isPremium;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, _isPremium);

    if (!_isPremium && _savedTags.length > 3) {
      final tagsToRemove = _savedTags.sublist(3);
      _savedTags = _savedTags.sublist(0, 3);
      _saveTagsSync();

      for (var i = 0; i < _accounts.length; i++) {
        final newTags = _accounts[i].tags.where((t) => !tagsToRemove.contains(t)).toList();
        if (newTags.length != _accounts[i].tags.length) {
          _accounts[i] = _accounts[i].copyWith(tags: newTags);
        }
      }
      _saveAccountsSync();
    }
    notifyListeners();
  }

  bool addGlobalTag(String tag) {
    final cleanTag = tag.trim().toUpperCase();
    if (cleanTag.isEmpty) return false;
    if (_savedTags.contains(cleanTag)) return true;

    int limite = _isPremium ? 10 : 3;
    if (_savedTags.length >= limite) return false;

    _savedTags.add(cleanTag);
    _saveTagsSync();
    notifyListeners();
    return true;
  }

  void removeGlobalTag(String tag) {
    _savedTags.remove(tag);
    for (var i = 0; i < _accounts.length; i++) {
      if (_accounts[i].tags.contains(tag)) {
        final newTags = List<String>.from(_accounts[i].tags)..remove(tag);
        _accounts[i] = _accounts[i].copyWith(tags: newTags);
      }
    }
    _saveAccountsSync();
    _saveTagsSync();
    notifyListeners();
  }

  void addAccount(Account account) {
    _accounts.insert(0, account);
    _saveAccountsSync();
    notifyListeners();
  }

  void updateAccount(Account updatedAccount) {
    final index = _accounts.indexWhere((a) => a.id == updatedAccount.id);
    if (index != -1) {
      _accounts[index] = updatedAccount;
      _saveAccountsSync();
      notifyListeners();
    }
  }

  void deleteAccount(String id) {
    _accounts.removeWhere((a) => a.id == id);
    _saveAccountsSync();
    notifyListeners();
  }

  void toggleStatus(String id) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      _accounts[index] = acc.copyWith(isReady: !acc.isReady);
      _saveAccountsSync();
      notifyListeners();
    }
  }

  void toggleFavorite(String id) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      _accounts[index] = acc.copyWith(isFavorite: !acc.isFavorite);
      _saveAccountsSync();
      notifyListeners();
    }
  }

  void setDays(String id, int days) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      _accounts[index] = acc.copyWith(expiresAt: DateTime.now().add(Duration(days: days)), hasExpiration: true);
      _saveAccountsSync();
      notifyListeners();
    }
  }

  List<Account> searchAccounts(String query) {
    final list = accounts;
    if (query.isEmpty) return list;
    final lowerQuery = query.toLowerCase();
    return list.where((a) {
      return a.title.toLowerCase().contains(lowerQuery) ||
             a.email.toLowerCase().contains(lowerQuery) ||
             a.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  enc.Key _getKeyFromPassword(String password) {
    final salted = password + 'VaporManagerCyberVaultSecretK3y!';
    return enc.Key.fromUtf8(salted.substring(0, 32));
  }

  String exportData(String password) {
    try {
      final List<Map<String, dynamic>> mapList = _accounts.map((a) => _safeToMap(a)).toList();
      final jsonString = json.encode(mapList);
      final key = _getKeyFromPassword(password);
      final encrypter = enc.Encrypter(enc.AES(key));
      return encrypter.encrypt(jsonString, iv: _iv).base64;
    } catch (e) {
      return 'Erro ao exportar os dados do sistema.';
    }
  }

  bool importData(String inputData, String password) {
    try {
      String jsonString;
      try {
        final key = _getKeyFromPassword(password);
        final encrypter = enc.Encrypter(enc.AES(key));
        jsonString = encrypter.decrypt64(inputData, iv: _iv);
      } catch (_) {
        jsonString = inputData;
      }
      final List<dynamic> decodedList = json.decode(jsonString);
      final List<Account> importedAccounts = [];
      for (var item in decodedList) {
        if (item is Map<String, dynamic>) {
          try {
            importedAccounts.add(_safeFromMap(item));
          } catch (_) {}
        }
      }
      for (var newAcc in importedAccounts) {
        if (!_accounts.any((oldAcc) => oldAcc.id == newAcc.id)) {
          _accounts.add(newAcc);
        }
      }
      _saveAccountsSync();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
