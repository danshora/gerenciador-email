import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as enc;

import 'account.dart';

// Integra o observador de ciclo de vida para detetar o exato milissegundo em que o app é minimizado
class AccountManager extends ChangeNotifier with WidgetsBindingObserver {
  static const String _vaultFile = 'vapor_bunker_accounts.dat';
  static const String _tagsFile = 'vapor_bunker_tags.dat';
  static const String _premiumKey = 'vapor_bunker_premium';
  static const String _devKey = 'vapor_bunker_dev';

  // Chaves blindadas (EXATAMENTE 16 e 32 bytes)
  final _iv = enc.IV.fromUtf8('VaporwaveInitVec'); 
  final enc.Key _masterKey = enc.Key.fromUtf8('VaporManagerStaticMasterKey32Bit');

  List<Account> _accounts = [];
  List<String> _savedTags = [];
  bool _isPremium = false;
  bool _isDevUnlocked = false; // NOVO: Persistência do Modo Dev
  bool _isLoaded = false;
  String? _sysDir;

  List<Account> get accounts {
    final favs = _accounts.where((a) => a.isFavorite).toList();
    final nonFavs = _accounts.where((a) => !a.isFavorite).toList();
    return [...favs, ...nonFavs];
  }

  List<String> get savedTags => _savedTags;
  bool get isLoading => !_isLoaded;
  bool get isPremium => _isPremium;
  bool get isDevUnlocked => _isDevUnlocked;

  AccountManager() {
    WidgetsBinding.instance.addObserver(this);
    _bootSystem();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🚨 DETETOR DE ENCERRAMENTO FORÇADO
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _nukeSave(); 
    }
  }

  // --- TRADUTORES SEGUROS (Anti-Crash de Datas) ---
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

  // --- INICIALIZAÇÃO BLINDADA ---
  Future<void> _bootSystem() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _sysDir = dir.path;

      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;
      _isDevUnlocked = prefs.getBool(_devKey) ?? false;

      final encrypter = enc.Encrypter(enc.AES(_masterKey, mode: enc.AESMode.cbc));

      // 1. LER CONTAS 
      String? accData;
      try {
        final file = File('$_sysDir/$_vaultFile');
        if (file.existsSync()) accData = file.readAsStringSync();
      } catch (_) {}
      accData ??= prefs.getString('backup_acc_v11');

      if (accData != null && accData.isNotEmpty) {
        try {
          final jsonString = encrypter.decrypt64(accData, iv: _iv);
          final decoded = json.decode(jsonString) as List<dynamic>;
          _accounts = decoded.map((item) => _safeFromMap(item as Map<String, dynamic>)).toList();
        } catch (_) {}
      }

      // 2. LER TAGS
      String? tagsData;
      try {
        final file = File('$_sysDir/$_tagsFile');
        if (file.existsSync()) tagsData = file.readAsStringSync();
      } catch (_) {}
      tagsData ??= prefs.getString('backup_tags_v11');

      if (tagsData != null && tagsData.isNotEmpty) {
        try {
          final jsonString = encrypter.decrypt64(tagsData, iv: _iv);
          _savedTags = List<String>.from(json.decode(jsonString));
        } catch (_) {}
      }

    } catch (_) {} finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  // --- O SEGREDO MILITAR: ESCRITA OBRIGATÓRIA NO SILÍCIO ---
  void _nukeSave() {
    if (!_isLoaded) return; 

    try {
      final encrypter = enc.Encrypter(enc.AES(_masterKey, mode: enc.AESMode.cbc));

      final accList = _accounts.map((a) => _safeToMap(a)).toList();
      final accData = encrypter.encrypt(json.encode(accList), iv: _iv).base64;
      final tagsData = encrypter.encrypt(json.encode(_savedTags), iv: _iv).base64;

      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('backup_acc_v11', accData);
        prefs.setString('backup_tags_v11', tagsData);
      });

      if (_sysDir != null) {
        final accFile = File('$_sysDir/$_vaultFile');
        final raf1 = accFile.openSync(mode: FileMode.write);
        raf1.writeStringSync(accData);
        raf1.flushSync(); 
        raf1.closeSync();

        final tagsFile = File('$_sysDir/$_tagsFile');
        final raf2 = tagsFile.openSync(mode: FileMode.write);
        raf2.writeStringSync(tagsData);
        raf2.flushSync(); 
        raf2.closeSync();
      }
    } catch (_) {}
  }

  // --- REGRAS DE NEGÓCIO ---

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
      _nukeSave();
    }
    notifyListeners();
  }
  
  // NOVO: Destravar modo desenvolvedor e salvar no disco
  Future<void> unlockDevMode() async {
    _isDevUnlocked = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devKey, true);
    notifyListeners();
  }

  bool addGlobalTag(String tag) {
    final cleanTag = tag.trim().toUpperCase();
    if (cleanTag.isEmpty) return false;
    if (_savedTags.contains(cleanTag)) return true;

    int limite = _isPremium ? 10 : 3;
    if (_savedTags.length >= limite) return false;

    _savedTags.add(cleanTag);
    _nukeSave();
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
    _nukeSave();
    notifyListeners();
  }

  void addAccount(Account account) {
    _accounts.insert(0, account);
    _nukeSave();
    notifyListeners();
  }

  void updateAccount(Account updatedAccount) {
    final index = _accounts.indexWhere((a) => a.id == updatedAccount.id);
    if (index != -1) {
      _accounts[index] = updatedAccount;
      _nukeSave(); 
      notifyListeners();
    }
  }

  void deleteAccount(String id) {
    _accounts.removeWhere((a) => a.id == id);
    _nukeSave();
    notifyListeners();
  }

  void toggleStatus(String id) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      _accounts[index] = acc.copyWith(isReady: !acc.isReady);
      _nukeSave();
      notifyListeners();
    }
  }

  void toggleFavorite(String id) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      _accounts[index] = acc.copyWith(isFavorite: !acc.isFavorite);
      _nukeSave();
      notifyListeners();
    }
  }

  void setDays(String id, int days) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      _accounts[index] = acc.copyWith(expiresAt: DateTime.now().add(Duration(days: days)), hasExpiration: true);
      _nukeSave();
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
      _nukeSave();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> factoryReset() async {
    _accounts.clear();
    _savedTags.clear();
    _isPremium = false;
    _isDevUnlocked = false; // Tranca o Dev novamente
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, false);
    await prefs.setBool(_devKey, false); // Tranca na memória
    
    _nukeSave(); 
    notifyListeners();
  }
}
