import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account.dart'; 

class AccountManager extends ChangeNotifier {
  static const String _storageKey = 'vaporwave_accounts';
  static const String _savedTagsKey = 'vaporwave_global_tags'; 
  static const String _premiumKey = 'vaporwave_is_premium'; 
  static const String _internalKeyName = 'vapor_hardware_master_key'; 
  
  final _iv = enc.IV.fromLength(16);
  
  // 🛡️ CORREÇÃO 1: Forçar persistência de hardware no Android. 
  // Impede que o sistema operativo "esqueça" a chave quando a RAM é limpa.
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  List<Account> _accounts = [];
  List<String> _savedTags = []; 
  bool _isLoading = true;
  bool _isPremium = false; 

  // 🛡️ CORREÇÃO 3: Trava contra sobreposição.
  bool _isDatabaseCorrupted = false;

  List<Account> get accounts {
    final favs = _accounts.where((a) => a.isFavorite).toList();
    final nonFavs = _accounts.where((a) => !a.isFavorite).toList();
    return [...favs, ...nonFavs];
  }
  
  List<String> get savedTags => _savedTags;
  bool get isLoading => _isLoading;
  bool get isPremium => _isPremium;

  AccountManager() {
    _loadAccounts();
  }

  Future<enc.Key> _getInternalMasterKey() async {
    String? base64Key = await _secureStorage.read(key: _internalKeyName);
    if (base64Key == null) {
      final secureRandom = enc.Key.fromSecureRandom(32);
      base64Key = secureRandom.base64;
      await _secureStorage.write(key: _internalKeyName, value: base64Key);
    }
    return enc.Key.fromBase64(base64Key);
  }

  enc.Key _getKeyFromPassword(String password) {
    final salted = password + 'VaporManagerCyberVaultSecretK3y!';
    return enc.Key.fromUtf8(salted.substring(0, 32));
  }

  Future<void> _loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;
      final masterKey = await _getInternalMasterKey();
      final encrypter = enc.Encrypter(enc.AES(masterKey));

      bool realizouMigracao = false;

      // 1. CARREGAR CONTAS
      final String? accountsData = prefs.getString(_storageKey);
      if (accountsData != null) {
        String jsonString;
        try {
          jsonString = encrypter.decrypt64(accountsData, iv: _iv);
        } catch (e) {
          // 🛡️ CORREÇÃO 2: Só migra se tiver a certeza de que é um texto limpo antigo (começa com "[")
          if (accountsData.trim().startsWith('[')) {
            jsonString = accountsData;
            realizouMigracao = true;
            debugPrint('Migrando banco de contas para encriptado...');
          } else {
            throw Exception('Falha na chave Mestra. Dados inacessíveis.');
          }
        }
        final List<dynamic> decodedList = json.decode(jsonString);
        _accounts = decodedList.map((item) => Account.fromMap(item as Map<String, dynamic>)).toList();
      }

      // 2. CARREGAR TAGS
      final String? tagsData = prefs.getString(_savedTagsKey);
      if (tagsData != null) {
        String tagsJsonString;
        try {
          tagsJsonString = encrypter.decrypt64(tagsData, iv: _iv);
        } catch (e) {
          if (tagsData.trim().startsWith('[')) {
            tagsJsonString = tagsData;
            realizouMigracao = true;
          } else {
            throw Exception('Falha nas tags.');
          }
        }
        _savedTags = List<String>.from(json.decode(tagsJsonString));
      }

      // Só grava logo no arranque se realmente atualizou o ficheiro antigo.
      if (realizouMigracao) {
        await _saveAccounts(force: true);
        await _saveGlobalTags(force: true);
      }

    } catch (e) {
      debugPrint('🚨 ERRO CRÍTICO AO LER O COFRE: $e');
      _isDatabaseCorrupted = true; // ATIVA A TRAVA DE SOBREPOSIÇÃO
      _accounts = [];
      _savedTags = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveAccounts({bool force = false}) async {
    // Se a aplicação deu erro de leitura na inicialização, IGNORA A GRAVAÇÃO.
    // Isto impede que o utilizador grave um ficheiro vazio em cima dos seus dados reais.
    if (_isDatabaseCorrupted && !force) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final masterKey = await _getInternalMasterKey();
      final encrypter = enc.Encrypter(enc.AES(masterKey));
      
      final String jsonString = json.encode(_accounts.map((a) => a.toMap()).toList());
      final String encryptedData = encrypter.encrypt(jsonString, iv: _iv).base64;
      
      await prefs.setString(_storageKey, encryptedData);
    } catch (e) {
      debugPrint('Erro ao salvar banco de dados: $e');
    }
  }

  Future<void> _saveGlobalTags({bool force = false}) async {
    if (_isDatabaseCorrupted && !force) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final masterKey = await _getInternalMasterKey();
      final encrypter = enc.Encrypter(enc.AES(masterKey));
      
      final String jsonString = json.encode(_savedTags);
      final String encryptedData = encrypter.encrypt(jsonString, iv: _iv).base64;
      
      await prefs.setString(_savedTagsKey, encryptedData);
    } catch (e) {
      debugPrint('Erro ao salvar tags globais: $e');
    }
  }

  // --- O RESTO MANTÉM-SE INTACTO ---

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
