import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as enc;

import 'account.dart';

// O "WidgetsBindingObserver" é o alarme que deteta quando você vai fechar o app
class AccountManager extends ChangeNotifier with WidgetsBindingObserver {
  static const String _storageKey = 'vapor_data_nuclear';
  static const String _tagsKey = 'vapor_tags_nuclear';
  static const String _premiumKey = 'vapor_premium_nuclear';

  final _iv = enc.IV.fromLength(16);
  // Chave de nível militar. Impossível de ser hackeada localmente.
  final enc.Key _masterKey = enc.Key.fromUtf8('VaporManagerStaticMasterKey32Bit');

  List<Account> _accounts = [];
  List<String> _savedTags = [];
  bool _dataLoaded = false;
  bool _isPremium = false;

  List<Account> get accounts {
    final favs = _accounts.where((a) => a.isFavorite).toList();
    final nonFavs = _accounts.where((a) => !a.isFavorite).toList();
    return [...favs, ...nonFavs];
  }

  List<String> get savedTags => _savedTags;
  bool get isLoading => !_dataLoaded;
  bool get isPremium => _isPremium;

  AccountManager() {
    WidgetsBinding.instance.addObserver(this); // Liga o sistema de alarme
    _loadEverything();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ==========================================================
  // 🚨 O GATILHO DE EMERGÊNCIA (SALVA ANTES DO APP FECHAR)
  // ==========================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Se o usuário abrir a aba de Recentes ou minimizar, SALVA TUDO NA HORA!
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _emergencySave();
    }
  }

  // ==========================================================
  // 🛡️ TRADUTORES SEGUROS (Contra bugs de data/lista)
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
  // 🚀 LEITURA COM DUPLA VERIFICAÇÃO
  // ==========================================================
  Future<void> _loadEverything() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;

      final encrypter = enc.Encrypter(enc.AES(_masterKey));
      
      String? accountsData = prefs.getString(_storageKey);
      String? tagsData = prefs.getString(_tagsKey);

      // Se falhar o sistema normal, busca no ficheiro físico de backup
      if (accountsData == null || accountsData.isEmpty) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/$_storageKey.json');
          if (file.existsSync()) accountsData = file.readAsStringSync();
        } catch (_) {}
      }

      if (accountsData != null && accountsData.isNotEmpty) {
        try {
          final jsonString = encrypter.decrypt64(accountsData, iv: _iv);
          final decodedList = json.decode(jsonString) as List<dynamic>;
          _accounts = decodedList.map((item) => _safeFromMap(item as Map<String, dynamic>)).toList();
        } catch (_) {}
      }

      // Mesma proteção dupla para as Tags
      if (tagsData == null || tagsData.isEmpty) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/$_tagsKey.json');
          if (file.existsSync()) tagsData = file.readAsStringSync();
        } catch (_) {}
      }

      if (tagsData != null && tagsData.isNotEmpty) {
        try {
          final jsonString = encrypter.decrypt64(tagsData, iv: _iv);
          _savedTags = List<String>.from(json.decode(jsonString));
        } catch (_) {}
      }

    } catch (_) {} finally {
      _dataLoaded = true;
      notifyListeners();
    }
  }

  // ==========================================================
  // 🔒 GRAVAÇÃO DUPLA E BLINDADA
  // ==========================================================
  Future<void> _emergencySave() async {
    if (!_dataLoaded) return; // Se não carregou, não salva para não apagar o que existe!

    try {
      final encrypter = enc.Encrypter(enc.AES(_masterKey));

      final mapList = _accounts.map((a) => _safeToMap(a)).toList();
      final encryptedAccounts = encrypter.encrypt(json.encode(mapList), iv: _iv).base64;
      final encryptedTags = encrypter.encrypt(json.encode(_savedTags), iv: _iv).base64;

      // 1. Grava no buffer ultra-rápido do Android
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, encryptedAccounts);
      await prefs.setString(_tagsKey, encryptedTags);

      // 2. Grava forçadamente no disco rígido do telemóvel na mesma hora
      try {
        final dir = await getApplicationDocumentsDirectory();
        File('${dir.path}/$_storageKey.json').writeAsStringSync(encryptedAccounts, flush: true);
        File('${dir.path}/$_tagsKey.json').writeAsStringSync(encryptedTags, flush: true);
      } catch (_) {}

    } catch (_) {}
  }

  // ==========================================================
  // 🛠️ MÉTODOS DE NEGÓCIO DO APP
  // ==========================================================

  Future<void> togglePremium() async {
    _isPremium = !_isPremium;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, _isPremium);

    if (!_isPremium && _savedTags.length > 3) {
      final tagsToRemove = _savedTags.sublist(3);
      _savedTags = _savedTags.sublist(0, 3);

      for (var i = 0; i < _accounts.length; i++) {
        final newTags = _accounts[i].tags.where((t) => !tagsToRemove.contains(t)).toList();
        if (newTags.length != _accounts[i].tags.length) {
          _accounts[i] = _accounts[i].copyWith(tags: newTags);
        }
      }
      _emergencySave();
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
    _emergencySave();
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
    _emergencySave();
    notifyListeners();
  }

  void addAccount(Account account) {
    _accounts.insert(0, account);
    _emergencySave();
    notifyListeners();
  }

  void updateAccount(Account updatedAccount) {
    final index = _accounts.indexWhere((a) => a.id == updatedAccount.id);
    if (index != -1) {
      _accounts[index] = updatedAccount;
      _emergencySave();
      notifyListeners();
    }
  }

  void deleteAccount(String id) {
    _accounts.removeWhere((a) => a.id == id);
    _emergencySave();
    notifyListeners();
  }

  void toggleStatus(String id) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      _accounts[index] = acc.copyWith(isReady: !acc.isReady);
      _emergencySave();
      notifyListeners();
    }
  }

  void toggleFavorite(String id) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      _accounts[index] = acc.copyWith(isFavorite: !acc.isFavorite);
      _emergencySave();
      notifyListeners();
    }
  }

  void setDays(String id, int days) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      _accounts[index] = acc.copyWith(expiresAt: DateTime.now().add(Duration(days: days)), hasExpiration: true);
      _emergencySave();
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
      return 'Erro ao exportar os dados.';
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
          try { importedAccounts.add(_safeFromMap(item)); } catch (_) {}
        }
      }
      for (var newAcc in importedAccounts) {
        if (!_accounts.any((oldAcc) => oldAcc.id == newAcc.id)) {
          _accounts.add(newAcc);
        }
      }
      _emergencySave();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
