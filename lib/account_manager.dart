import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account.dart'; 

class AccountManager extends ChangeNotifier {
  static const String _storageKey = 'vaporwave_accounts';
  static const String _storageKeyFallback = 'vaporwave_accounts_backup'; // Cofre de Paraquedas
  static const String _savedTagsKey = 'vaporwave_global_tags'; 
  static const String _savedTagsKeyFallback = 'vaporwave_tags_backup'; 
  static const String _premiumKey = 'vaporwave_is_premium'; 
  static const String _internalKeyName = 'vapor_hardware_master_key'; 
  
  final _iv = enc.IV.fromLength(16);
  
  // Chave estática de emergência (Oculta no código). 
  // Salva a vida dos dados caso o Android apague o Keystore de Hardware.
  final enc.Key _fallbackKey = enc.Key.fromUtf8('VaporManagerCyberVaultF4llb4ckK3');
  
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

  // Busca a chave no hardware. Tenta ler nas configurações antigas para resgatar dados perdidos.
  Future<enc.Key> _getInternalMasterKey() async {
    String? base64Key;
    
    // Tentativa 1: Formato padrão sem opções
    try {
      base64Key = await const FlutterSecureStorage().read(key: _internalKeyName);
    } catch (_) {}

    // Tentativa 2: Formato da nossa última atualização que pode ter ocultado a chave
    if (base64Key == null) {
      try {
        base64Key = await const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true)
        ).read(key: _internalKeyName);
      } catch (_) {}
    }

    // Se o Android realmente destruiu tudo, gera uma nova chave mestre do zero
    if (base64Key == null) {
      final secureRandom = enc.Key.fromSecureRandom(32);
      base64Key = secureRandom.base64;
      await const FlutterSecureStorage().write(key: _internalKeyName, value: base64Key);
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
      final fallbackEncrypter = enc.Encrypter(enc.AES(_fallbackKey));

      bool realizouMigracao = false;

      // ==========================================
      // 1. CARREGAR CONTAS COM RESGATE AUTOMÁTICO
      // ==========================================
      String? jsonString;
      final String? encryptedData = prefs.getString(_storageKey);
      
      // A. Tenta ler a nível Militar (Hardware)
      if (encryptedData != null) {
        try {
          jsonString = encrypter.decrypt64(encryptedData, iv: _iv);
        } catch (_) {
          debugPrint('Falha no Keystore. Tentando Resgate...');
        }
      }

      // B. Se falhou, aciona o Cofre de Paraquedas
      if (jsonString == null) {
        final String? fallbackData = prefs.getString(_storageKeyFallback);
        if (fallbackData != null) {
          try {
            jsonString = fallbackEncrypter.decrypt64(fallbackData, iv: _iv);
            realizouMigracao = true; // Força a re-gravação no novo Keystore reparado
            debugPrint('DADOS DE CONTAS RESGATADOS COM SUCESSO!');
          } catch (_) {}
        }
      }

      // C. Se AINDA falhou, tenta ler como texto limpo (caso seja um utilizador da primeiríssima versão)
      if (jsonString == null && encryptedData != null) {
        if (encryptedData.trim().startsWith('[')) {
          jsonString = encryptedData;
          realizouMigracao = true;
        }
      }

      if (jsonString != null) {
        final List<dynamic> decodedList = json.decode(jsonString);
        _accounts = decodedList.map((item) => Account.fromMap(item as Map<String, dynamic>)).toList();
      }

      // ==========================================
      // 2. CARREGAR TAGS COM RESGATE AUTOMÁTICO
      // ==========================================
      String? tagsJsonString;
      final String? tagsData = prefs.getString(_savedTagsKey);

      if (tagsData != null) {
        try {
          tagsJsonString = encrypter.decrypt64(tagsData, iv: _iv);
        } catch (_) {}
      }

      if (tagsJsonString == null) {
        final String? tagsFallback = prefs.getString(_savedTagsKeyFallback);
        if (tagsFallback != null) {
          try {
            tagsJsonString = fallbackEncrypter.decrypt64(tagsFallback, iv: _iv);
            realizouMigracao = true;
          } catch (_) {}
        }
      }

      if (tagsJsonString == null && tagsData != null) {
        if (tagsData.trim().startsWith('[')) {
          tagsJsonString = tagsData;
          realizouMigracao = true;
        }
      }

      if (tagsJsonString != null) {
        _savedTags = List<String>.from(json.decode(tagsJsonString));
      }

      // Se fizemos algum resgate, salva novamente para atualizar o Keystore falhado
      if (realizouMigracao) {
        await _saveAccounts();
        await _saveGlobalTags();
      }

    } catch (e) {
      debugPrint('Erro extremo de inicialização: $e');
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
      final fallbackEncrypter = enc.Encrypter(enc.AES(_fallbackKey));
      
      final String jsonString = json.encode(_accounts.map((a) => a.toMap()).toList());
      
      // 1. Salva no Cofre Militar Principal (Hardware)
      final String encryptedData = encrypter.encrypt(jsonString, iv: _iv).base64;
      await prefs.setString(_storageKey, encryptedData);
      
      // 2. Salva no Cofre de Paraquedas (Software)
      final String fallbackData = fallbackEncrypter.encrypt(jsonString, iv: _iv).base64;
      await prefs.setString(_storageKeyFallback, fallbackData);

    } catch (e) {
      debugPrint('Erro ao salvar contas: $e');
    }
  }

  Future<void> _saveGlobalTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final masterKey = await _getInternalMasterKey();
      final encrypter = enc.Encrypter(enc.AES(masterKey));
      final fallbackEncrypter = enc.Encrypter(enc.AES(_fallbackKey));
      
      final String jsonString = json.encode(_savedTags);
      
      final String encryptedData = encrypter.encrypt(jsonString, iv: _iv).base64;
      await prefs.setString(_savedTagsKey, encryptedData);

      final String fallbackData = fallbackEncrypter.encrypt(jsonString, iv: _iv).base64;
      await prefs.setString(_savedTagsKeyFallback, fallbackData);

    } catch (e) {
      debugPrint('Erro ao salvar tags: $e');
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
