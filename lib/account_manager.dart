import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Mantido apenas para o estado do Premium
import 'package:encrypt/encrypt.dart' as enc;

import 'account.dart'; 

class AccountManager extends ChangeNotifier {
  static const String _accountsFileName = 'vaporwave_accounts_v4.json'; 
  static const String _tagsFileName = 'vaporwave_global_tags_v4.json'; 
  static const String _softwareKeyName = 'vapor_software_master_key_v4.key'; 
  static const String _premiumKey = 'vaporwave_is_premium_v4'; 
  
  final _iv = enc.IV.fromLength(16);
  
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

  // --- NÚCLEO DE FICHEIROS FÍSICOS ---

  // Retorna a pasta segura e invisível da aplicação no telemóvel
  Future<String> _getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Lê ou cria a Chave Mestra Física
  Future<enc.Key> _getMasterKey() async {
    final dirPath = await _getAppDirectory();
    final keyFile = File('$dirPath/$_softwareKeyName');

    if (await keyFile.exists()) {
      final base64Key = await keyFile.readAsString();
      return enc.Key.fromBase64(base64Key);
    } else {
      final secureRandom = enc.Key.fromSecureRandom(32);
      final base64Key = secureRandom.base64;
      await keyFile.writeAsString(base64Key);
      return enc.Key.fromBase64(base64Key);
    }
  }

  enc.Key _getKeyFromPassword(String password) {
    final salted = password + 'VaporManagerCyberVaultSecretK3y!';
    return enc.Key.fromUtf8(salted.substring(0, 32));
  }

  // --- LEITURA ABSOLUTA ---
  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;
      
      final masterKey = await _getMasterKey();
      final encrypter = enc.Encrypter(enc.AES(masterKey));
      final dirPath = await _getAppDirectory();

      // 1. CARREGAR CONTAS
      final accountsFile = File('$dirPath/$_accountsFileName');
      if (await accountsFile.exists()) {
        try {
          final encryptedAccounts = await accountsFile.readAsString();
          final jsonString = encrypter.decrypt64(encryptedAccounts, iv: _iv);
          final List<dynamic> decodedList = json.decode(jsonString);
          _accounts = decodedList.map((item) => Account.fromMap(item as Map<String, dynamic>)).toList();
        } catch (e) {
          debugPrint('Falha ao descriptografar contas físicas: $e');
        }
      }

      // 2. CARREGAR TAGS
      final tagsFile = File('$dirPath/$_tagsFileName');
      if (await tagsFile.exists()) {
        try {
          final encryptedTags = await tagsFile.readAsString();
          final tagsJsonString = encrypter.decrypt64(encryptedTags, iv: _iv);
          _savedTags = List<String>.from(json.decode(tagsJsonString));
        } catch (e) {
          debugPrint('Falha ao descriptografar tags físicas: $e');
        }
      }

    } catch (e) {
      debugPrint('Erro extremo na leitura física: $e');
    } finally {
      _isLoading = false; 
      notifyListeners();
    }
  }

  // --- GRAVAÇÃO ABSOLUTA ---
  Future<void> _saveAccounts() async {
    if (_isLoading) return; 

    try {
      final masterKey = await _getMasterKey();
      final encrypter = enc.Encrypter(enc.AES(masterKey));
      final dirPath = await _getAppDirectory();
      
      final String jsonString = json.encode(_accounts.map((a) => a.toMap()).toList());
      final String encryptedData = encrypter.encrypt(jsonString, iv: _iv).base64;
      
      final accountsFile = File('$dirPath/$_accountsFileName');
      await accountsFile.writeAsString(encryptedData);
    } catch (e) {
      debugPrint('Erro ao gravar contas físicas: $e');
    }
  }

  Future<void> _saveGlobalTags() async {
    if (_isLoading) return; 

    try {
      final masterKey = await _getMasterKey();
      final encrypter = enc.Encrypter(enc.AES(masterKey));
      final dirPath = await _getAppDirectory();
      
      final String jsonString = json.encode(_savedTags);
      final String encryptedData = encrypter.encrypt(jsonString, iv: _iv).base64;
      
      final tagsFile = File('$dirPath/$_tagsFileName');
      await tagsFile.writeAsString(encryptedData);
    } catch (e) {
      debugPrint('Erro ao gravar tags físicas: $e');
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
      final List<Account> importedAccounts = decodedList.map((item) => Account.fromMap(item as Map<String, dynamic>)).toList();
      for (var newAcc in importedAccounts) {
        if (!_accounts.any((oldAcc) => oldAcc.id == newAcc.id)) _accounts.add(newAcc);
      }
      _saveAccounts();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
