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
  final _secureStorage = const FlutterSecureStorage();
  
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
    _loadAccounts();
  }

  // --- NÚCLEO DE SEGURANÇA (CRIPTOGRAFIA EM REPOUSO) ---
  
  // Gera e recupera uma chave mestre única presa ao hardware do celular
  Future<enc.Key> _getInternalMasterKey() async {
    String? base64Key = await _secureStorage.read(key: _internalKeyName);
    if (base64Key == null) {
      // Se não existir, cria uma nova chave de 32 bytes e salva no Keystore
      final secureRandom = enc.Key.fromSecureRandom(32);
      base64Key = secureRandom.base64;
      await _secureStorage.write(key: _internalKeyName, value: base64Key);
    }
    return enc.Key.fromBase64(base64Key);
  }

  // Chave derivada para a exportação (onde o usuário digita a senha dele)
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

      // 1. CARREGAR CONTAS
      final String? accountsData = prefs.getString(_storageKey);
      if (accountsData != null) {
        String jsonString;
        try {
          // Tenta desencriptar (Formato Novo Seguro)
          jsonString = encrypter.decrypt64(accountsData, iv: _iv);
        } catch (e) {
          // Se falhar, assume que é do Formato Antigo (Texto Limpo) e converte
          jsonString = accountsData;
          debugPrint('Migrando banco de contas para formato encriptado...');
        }
        final List<dynamic> decodedList = json.decode(jsonString);
        _accounts = decodedList.map((item) => Account.fromMap(item as Map<String, dynamic>)).toList();
      }

      // 2. CARREGAR TAGS GLOBAIS
      final String? tagsData = prefs.getString(_savedTagsKey);
      if (tagsData != null) {
        String tagsJsonString;
        try {
          tagsJsonString = encrypter.decrypt64(tagsData, iv: _iv);
        } catch (e) {
          tagsJsonString = tagsData;
          debugPrint('Migrando banco de tags para formato encriptado...');
        }
        _savedTags = List<String>.from(json.decode(tagsJsonString));
      }

      // Se passou por uma migração, salva imediatamente no novo formato blindado
      if (accountsData != null || tagsData != null) {
        _saveAccounts();
        _saveGlobalTags();
      }

    } catch (e) {
      debugPrint('Erro ao carregar/desencriptar dados: $e');
      _accounts = [];
      _savedTags = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final masterKey = await _getInternalMasterKey();
      final encrypter = enc.Encrypter(enc.AES(masterKey));
      
      final String jsonString = json.encode(_accounts.map((a) => a.toMap()).toList());
      final String encryptedData = encrypter.encrypt(jsonString, iv: _iv).base64;
      
      await prefs.setString(_storageKey, encryptedData);
    } catch (e) {
      debugPrint('Erro crítico ao encriptar o cofre: $e');
    }
  }

  Future<void> _saveGlobalTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final masterKey = await _getInternalMasterKey();
      final encrypter = enc.Encrypter(enc.AES(masterKey));
      
      final String jsonString = json.encode(_savedTags);
      final String encryptedData = encrypter.encrypt(jsonString, iv: _iv).base64;
      
      await prefs.setString(_savedTagsKey, encryptedData);
    } catch (e) {
      debugPrint('Erro ao salvar tags encriptadas: $e');
    }
  }

  // --- LÓGICA DE NEGÓCIO DO APP ---

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

  // Exportar para fora do aparelho usa a senha que o usuário digitar (mantido como estava)
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
