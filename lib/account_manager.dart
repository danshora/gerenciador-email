import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as enc;

import 'account.dart'; 

class AccountManager extends ChangeNotifier {
  static const String _storageKey = 'vaporwave_accounts';
  
  final _iv = enc.IV.fromLength(16); // Vetor de inicialização padrão
  
  List<Account> _accounts = [];
  bool _isLoading = true;

  List<Account> get accounts {
    final favs = _accounts.where((a) => a.isFavorite).toList();
    final nonFavs = _accounts.where((a) => !a.isFavorite).toList();
    return [...favs, ...nonFavs];
  }
  
  bool get isLoading => _isLoading;

  AccountManager() {
    _loadAccounts();
  }

  // GERA UMA CHAVE ÚNICA BASEADA NA SENHA DO USUÁRIO
  enc.Key _getKeyFromPassword(String password) {
    // Mistura a senha com um sal para garantir exatos 32 caracteres (exigência do AES-256)
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
    } catch (e) {
      debugPrint('Erro ao carregar as contas do Neon Drive: $e');
      _accounts = [];
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
             a.description.toLowerCase().contains(lowerQuery) ||
             a.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  List<Account> filterByCategory(String category) {
    final list = accounts;
    if (category == 'Todas') return list;
    return list.where((a) => a.category == category || a.tags.contains(category)).toList();
  }

  // EXPORTAÇÃO EXIGE SENHA AGORA
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

  // IMPORTAÇÃO EXIGE A MESMA SENHA
  bool importData(String inputData, String password) {
    try {
      String jsonString;
      
      // Tenta destrancar usando a senha fornecida
      try {
        final key = _getKeyFromPassword(password);
        final encrypter = enc.Encrypter(enc.AES(key));
        jsonString = encrypter.decrypt64(inputData, iv: _iv);
      } catch (_) {
        // Se a senha falhar, tenta ver se é um backup muito antigo (texto puro)
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
      debugPrint('Falha ao restaurar dados: $e');
      return false; // Retorna falso se a senha estiver errada ou o arquivo corrompido
    }
  }
}
