import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as enc;

import 'account.dart'; 

class AccountManager extends ChangeNotifier {
  static const String _storageKey = 'vaporwave_accounts';
  static const String _savedTagsKey = 'vaporwave_global_tags'; 
  
  final _iv = enc.IV.fromLength(16);
  
  List<Account> _accounts = [];
  List<String> _savedTags = []; 
  bool _isLoading = true;

  List<Account> get accounts {
    final favs = _accounts.where((a) => a.isFavorite).toList();
    final nonFavs = _accounts.where((a) => !a.isFavorite).toList();
    return [...favs, ...nonFavs];
  }
  
  List<String> get savedTags => _savedTags;
  bool get isLoading => _isLoading;

  AccountManager() {
    _loadAccounts();
  }

  enc.Key _getKeyFromPassword(String password) {
    final salted = password + 'VaporManagerCyberVaultSecretK3y!';
    return enc.Key.fromUtf8(salted.substring(0, 32));
  }

  Future<void> _loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String? accountsJson = prefs.getString(_storageKey);
      if (accountsJson != null) {
        final List<dynamic> decodedList = json.decode(accountsJson);
        _accounts = decodedList.map((item) => Account.fromMap(item as Map<String, dynamic>)).toList();
      }

      final String? tagsJson = prefs.getString(_savedTagsKey);
      if (tagsJson != null) {
        _savedTags = List<String>.from(json.decode(tagsJson));
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do Neon Drive: $e');
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
      final String encodedList = json.encode(_accounts.map((a) => a.toMap()).toList());
      await prefs.setString(_storageKey, encodedList);
    } catch (e) {
      debugPrint('Erro ao salvar no Neon Drive: $e');
    }
  }

  Future<void> _saveGlobalTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedTagsKey, json.encode(_savedTags));
    } catch (e) {
      debugPrint('Erro ao salvar tags globais: $e');
    }
  }

  bool addGlobalTag(String tag) {
    final cleanTag = tag.trim();
    if (cleanTag.isEmpty) return false;
    if (_savedTags.contains(cleanTag)) return true; 
    
    if (_savedTags.length >= 3) {
      return false; 
    }
    
    _savedTags.add(cleanTag);
    _saveGlobalTags();
    notifyListeners();
    return true;
  }

  void removeGlobalTag(String tag) {
    _savedTags.remove(tag);
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
      _accounts[index] = acc.copyWith(expiresAt: DateTime.now().add(Duration(days: days)));
      _saveAccounts();
      notifyListeners();
    }
  }

  void incrementDays(String id) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      if (acc.expiresAt != null) {
        _accounts[index] = acc.copyWith(expiresAt: acc.expiresAt!.add(const Duration(days: 1)));
        _saveAccounts();
        notifyListeners();
      }
    }
  }

  void decrementDays(String id) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final acc = _accounts[index];
      if (acc.expiresAt != null) {
        final newDate = acc.expiresAt!.subtract(const Duration(days: 1));
        if (newDate.isAfter(DateTime.now())) {
          _accounts[index] = acc.copyWith(expiresAt: newDate);
          _saveAccounts();
          notifyListeners();
        } else {
          _accounts[index] = acc.copyWith(expiresAt: DateTime.now());
          _saveAccounts();
          notifyListeners();
        }
      }
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
      final encrypted = encrypter.encrypt(jsonString, iv: _iv);
      return encrypted.base64;
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
      final List<Account> importedAccounts = decodedList
          .map((item) => Account.fromMap(item as Map<String, dynamic>))
          .toList();
      
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
