import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:encrypt/encrypt.dart' as enc;

import 'account.dart'; 

class AccountManager extends ChangeNotifier {
  static const String _storageKey = 'vaporwave_accounts_v6.json'; 
  static const String _savedTagsKey = 'vaporwave_global_tags_v6.json'; 
  static const String _premiumKey = 'vaporwave_is_premium_v6'; 
  
  final _iv = enc.IV.fromLength(16);
  
  // Chave Mestre Estática de 32 bytes estável e imune a resets
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

  Future<String> _getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  enc.Key _getKeyFromPassword(String password) {
    final salted = password + 'VaporManagerCyberVaultSecretK3y!';
    return enc.Key.fromUtf8(salted.substring(0, 32));
  }

  // --- LEITURA BLINDADA ---
  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;
      
      final encrypter = enc.Encrypter(enc.AES(_masterKey));
      final dirPath = await _getAppDirectory();

      // 1. CARREGAR CONTAS COM CAPTURA DE ERRO POR ITEM
      final accountsFile = File('$dirPath/$_storageKey');
      if (await accountsFile.exists()) {
        try {
          final encryptedAccounts = await accountsFile.readAsString();
          // CORREÇÃO AQUI: iv: _iv em vez de id: _iv
          final jsonString = encrypter.decrypt64(encryptedAccounts, iv: _iv);
          final List<dynamic> decodedList = json.decode(jsonString);
          
          final List<Account> loadedAccounts = [];
          for (var item in decodedList) {
            try {
              if (item is Map<String, dynamic>) {
                loadedAccounts.add(Account.fromMap(item));
              }
            } catch (itemError) {
              debugPrint('Aviso: Ignorada conta malformada para evitar corrupção: $itemError');
            }
          }
          _accounts = loadedAccounts;
        } catch (e) {
          debugPrint('Erro na decodificação do bloco de contas: $e');
        }
      }

      // 2. CARREGAR TAGS
      final tagsFile = File('$dirPath/$_savedTagsKey');
      if (await tagsFile.exists()) {
        try {
          final encryptedTags = await tagsFile.readAsString();
          // CORREÇÃO AQUI: iv: _iv em vez de id: _iv
          final tagsJsonString = encrypter.decrypt64(encryptedTags, iv: _iv);
          _savedTags = List<String>.from(json.decode(tagsJsonString));
        } catch (e) {
          debugPrint('Erro na decodificação do bloco de tags: $e');
        }
      }

    } catch (e) {
      debugPrint('Erro geral crítico de leitura física: $e');
    } finally {
      _isLoading = false; 
      notifyListeners();
    }
  }

  // --- GRAVAÇÃO ABSOLUTA COM FLUSH ATIVO ---
  Future<void> _saveAccounts() async {
    if (_isLoading) return; 

    try {
      final encrypter = enc.Encrypter(enc.AES(_masterKey));
      final dirPath = await _getAppDirectory();
      
      final String jsonString = json.encode(_accounts.map((a) => a.toMap()).toList());
      final String encryptedData = encrypter.encrypt(jsonString, iv: _iv).base64;
      
      final accountsFile = File('$dirPath/$_storageKey');
      
      await accountsFile.writeAsString(encryptedData, flush: true);
    } catch (e) {
      debugPrint('Erro ao escrever ficheiro físico de contas: $e');
    }
  }

  Future<void> _saveGlobalTags() async {
    if (_isLoading) return; 

    try {
      final encrypter = enc.Encrypter(enc.AES(_masterKey));
      final dirPath = await _getAppDirectory();
      
      final String jsonString = json.encode(_savedTags);
      final String encryptedData = encrypter.encrypt(jsonString, iv: _iv).base64;
      
      final tagsFile = File('$dirPath/$_savedTagsKey');
      await tagsFile.writeAsString(encryptedData, flush: true);
    } catch (e) {
      debugPrint('Erro ao escrever ficheiro físico de tags: $e');
    }
  }

  // --- LÓGICA DE NEGÓCIO ---

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
      final jsonString = json.encode(_accounts.map((a) => a.toMap()).toList());
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
        try {
          if (item is Map<String, dynamic>) {
            importedAccounts.add(Account.fromMap(item));
          }
        } catch (_) {}
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
