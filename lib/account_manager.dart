import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account.dart'; 

class AccountManager extends ChangeNotifier {
  static const String _storageKey = 'vaporwave_accounts';
  
  List<Account> _accounts = [];
  bool _isLoading = true;

  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;

  AccountManager() {
    _loadAccounts();
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

  // --- NOVA FUNÇÃO PARA A LISTA DE DIAS ---
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
    if (query.isEmpty) return _accounts;
    final lowerQuery = query.toLowerCase();
    return _accounts.where((a) {
      return a.title.toLowerCase().contains(lowerQuery) ||
             a.description.toLowerCase().contains(lowerQuery) ||
             a.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  List<Account> filterByCategory(String category) {
    if (category == 'Todas') return _accounts;
    return _accounts.where((a) => a.category == category || a.tags.contains(category)).toList();
  }

  String exportData() {
    try {
      return json.encode(_accounts.map((a) => a.toMap()).toList());
    } catch (e) {
      return 'Erro ao exportar os dados do sistema.';
    }
  }
}
