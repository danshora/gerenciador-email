import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:encrypt/encrypt.dart' as enc;

import 'account.dart'; 

class AccountManager extends ChangeNotifier {
  // V9: Registo limpo para evitar conflitos
  static const String _storageKey = 'vaporwave_vault_v9'; 
  static const String _savedTagsKey = 'vaporwave_tags_v9'; 
  static const String _premiumKey = 'vaporwave_premium_v9'; 
  
  final _iv = enc.IV.fromLength(16);
  final enc.Key _masterKey = enc.Key.fromUtf8('VaporManagerStaticMasterKey32Bit');
  
  List<Account> _accounts = [];
  List<String> _savedTags = []; 
  bool _isLoading = true;
  bool _isPremium = false; 

  List<Account> get accounts {
    final favs = _accounts.where((a) => a.isFavorite).toList();
    final nonFavs = _accounts.where((a) => !a.isFavorite).toList();
    return [...favs, ...nonFavs];
  }
  
  List<String> get savedTags => _savedTags;
  bool get isLoading => _isLoading;
  bool get isPremium => _isPremium;

  AccountManager() {
    _loadAllData();
  }

  enc.Key _getKeyFromPassword(String password) {
    final salted = password + 'VaporManagerCyberVaultSecretK3y!';
    return enc.Key.fromUtf8(salted.substring(0, 32));
  }

  // ==========================================================
  // 🛡️ SERIALIZADORES À PROVA DE BALAS (O FIM DOS CRASHES)
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
      'createdAt': a.createdAt.toIso8601String(), // Nunca mais dá crash aqui!
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
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [], // Nunca mais dá crash na Lista!
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
      expiresAt: map['expiresAt'] != null ? DateTime.tryParse(map['expiresAt'].toString()) : null,
    );
  }

  // ==========================================================

  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;
      
      final encrypter = enc.Encrypter(enc.AES(_masterKey));

      // 1. CARREGAR CONTAS
      final String? encryptedAccounts = prefs.getString(_storageKey);
      if (encryptedAccounts != null && encryptedAccounts.isNotEmpty) {
        try {
          final jsonString = encrypter.decrypt64(encryptedAccounts, iv: _iv);
          final List<dynamic> decodedList = json.decode(jsonString);
          
          final List<Account> loadedAccounts = [];
          for (var item in decodedList) {
            if (item is Map<String, dynamic>) {
              try {
                loadedAccounts.add(_safeFromMap(item)); // Usa o construtor seguro
              } catch (_) {}
            }
          }
          _accounts = loadedAccounts;
        } catch (e) {
          debugPrint('Erro na decodificação: $e');
        }
      }

      // 2. CARREGAR TAGS
      final String? encryptedTags = prefs.getString(_savedTagsKey);
      if (encryptedTags != null && encryptedTags.isNotEmpty) {
        try {
          final tagsJsonString = encrypter.decrypt64(encryptedTags, iv: _iv);
          _savedTags = List<String>.from(json.decode(tagsJsonString));
        } catch (e) {
          debugPrint('Erro na decodificação de tags: $e');
        }
      }

    } catch (e) {
      debugPrint('Erro no carregamento: $e');
    } finally {
      _isLoading = false; 
      notifyListeners();
    }
  }

  Future<void> _saveAccounts() async {
    if (_isLoading) return; 

    try {
      final prefs = await SharedPreferences.getInstance();
      final encrypter = enc.Encrypter(enc.AES(_masterKey));
      
      // AQUI ESTAVA O ERRO SILENCIOSO. AGORA ESTÁ PROTEGIDO!
      final List<Map<String, dynamic>> mapList = _accounts.map((a) => _safeToMap(a)).toList();
      final String jsonString = json.encode(mapList);
      
      final String encryptedData = encrypter.encrypt(jsonString, iv: _iv).base64;
      await prefs.setString(_storageKey, encryptedData);
    } catch (e) {
      debugPrint('Erro crítico ao salvar: $e'); // O erro finalmente seria visto aqui
    }
  }

  Future<void> _saveGlobalTags() async {
    if (_isLoading) return; 

    try {
      final prefs = await SharedPreferences.getInstance();
      final encrypter = enc.Encrypter(enc.AES(_masterKey));
      
      final String jsonString = json.encode(_savedTags);
      final String encryptedData = encrypter.encrypt(jsonString, iv: _iv).base64;
      
      await prefs.setString(_savedTagsKey, encryptedData);
    } catch (e) {
      debugPrint('Erro crítico nas tags: $e');
    }
  }

  // --- LÓGICA DE NEGÓCIO INTACTA ---

  Future<void> togglePremium() async {
    _isPremium = !_isPremium;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, _isPremium);

    if (!_isPremium && _savedTags.length > 3) {
      final tagsToRemove = _savedTags.sublist(3);
      _savedTags = _savedTags.sublist(0, 3);
      await _saveGlobalTags();

      for (var i = 0; i < _accounts.length; i++) {
        final newTags = _accounts[i].tags.where((t) => !tagsToRemove.contains(t)).toList();
        if (newTags.length != _accounts[i].tags.length) {
          _accounts[i] = _accounts[i].copyWith(tags: newTags);
        }
      }
      await _saveAccounts();
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
    _saveGlobalTags();
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
    _saveAccounts();
    _saveGlobalTags();
    notifyListeners();
  }

  void addAccount(Account account) {
    _accounts.insert(0, account);
    _saveAccounts();
    notifyListeners();
  }

  void updateAccount(Account updatedAccount) {
    final index = _accounts.indexWhere((a) => a.id == updatedAccount.id);
    if (index != -1) {
      _accounts[index] = updatedAccount;
      _saveAccounts();
      notifyListeners();
    }
  }

  void deleteAccount(String id) {
    _accounts.removeWhere((a) => a.id == id);
    _saveAccounts();
    notifyListeners();
  }

  void toggleStatus(String id) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      _accounts[index] = acc.copyWith(isReady: !acc.isReady);
      _saveAccounts();
      notifyListeners();
    }
  }

  void toggleFavorite(String id) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      _accounts[index] = acc.copyWith(isFavorite: !acc.isFavorite);
      _saveAccounts();
      notifyListeners();
    }
  }

  void setDays(String id, int days) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      _accounts[index] = acc.copyWith(expiresAt: DateTime.now().add(Duration(days: days)), hasExpiration: true);
      _saveAccounts();
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

  String exportData(String password) {
    try {
      // Uso do serializador seguro na exportação
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
            importedAccounts.add(_safeFromMap(item)); // Uso do deserializador seguro
          } catch (_) {}
        }
      }
      for (var newAcc in importedAccounts) {
        if (!_accounts.any((oldAcc) => oldAcc.id == newAcc.id)) {
          _accounts.add(newAcc);
        }
      }
      _saveAccounts();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
