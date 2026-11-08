import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/snippet_model.dart';
import '../models/ssh_host.dart';
import '../models/ssh_key_pair_model.dart';

class StorageService {
  static const _hostsKey = 'ssh_hosts_list';
  static const _keysMetaKey = 'ssh_keys_meta_list';
  static const _snippetsKey = 'ssh_snippets_list';
  static const _knownHostsKey = 'ssh_known_hosts';
  static const _fontSizeKey = 'terminal_font_size';
  static const _languageKey = 'app_language_pref';
  static const _autoUpdateKey = 'app_auto_update_pref';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  StorageService(this._prefs, this._secureStorage);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();
    return StorageService(prefs, secureStorage);
  }

  // ===================== HOSTS =====================

  List<SSHHost> getHosts() {
    final raw = _prefs.getStringList(_hostsKey) ?? [];
    return raw.map((item) => SSHHost.fromJson(item)).toList();
  }

  Future<void> saveHost(SSHHost host, {String? password}) async {
    final hosts = getHosts();
    final index = hosts.indexWhere((h) => h.id == host.id);
    if (index >= 0) {
      hosts[index] = host;
    } else {
      hosts.add(host);
    }
    await _prefs.setStringList(_hostsKey, hosts.map((h) => h.toJson()).toList());

    if (password != null) {
      await _secureStorage.write(key: 'host_pwd_${host.id}', value: password);
    }
  }

  Future<void> deleteHost(String hostId) async {
    final hosts = getHosts();
    hosts.removeWhere((h) => h.id == hostId);
    await _prefs.setStringList(_hostsKey, hosts.map((h) => h.toJson()).toList());
    await _secureStorage.delete(key: 'host_pwd_$hostId');
  }

  Future<String?> getHostPassword(String hostId) async {
    return await _secureStorage.read(key: 'host_pwd_$hostId');
  }

  // ===================== KEY PAIRS =====================

  List<SSHKeyPairModel> getKeyPairs() {
    final raw = _prefs.getStringList(_keysMetaKey) ?? [];
    return raw.map((item) => SSHKeyPairModel.fromJson(item)).toList();
  }

  Future<void> saveKeyPair(SSHKeyPairModel keyPair, {String? passphrase}) async {
    final keys = getKeyPairs();
    final index = keys.indexWhere((k) => k.id == keyPair.id);
    if (index >= 0) {
      keys[index] = keyPair;
    } else {
      keys.add(keyPair);
    }
    await _prefs.setStringList(_keysMetaKey, keys.map((k) => k.toJson()).toList());

    // Store private key securely
    await _secureStorage.write(
      key: 'key_priv_${keyPair.id}',
      value: keyPair.privateKeyPem,
    );

    if (passphrase != null && passphrase.isNotEmpty) {
      await _secureStorage.write(
        key: 'key_pass_${keyPair.id}',
        value: passphrase,
      );
    }
  }

  Future<void> deleteKeyPair(String keyId) async {
    final keys = getKeyPairs();
    keys.removeWhere((k) => k.id == keyId);
    await _prefs.setStringList(_keysMetaKey, keys.map((k) => k.toJson()).toList());
    await _secureStorage.delete(key: 'key_priv_$keyId');
    await _secureStorage.delete(key: 'key_pass_$keyId');
  }

  Future<String?> getPrivateKeyPem(String keyId) async {
    return await _secureStorage.read(key: 'key_priv_$keyId');
  }

  Future<String?> getKeyPassphrase(String keyId) async {
    return await _secureStorage.read(key: 'key_pass_$keyId');
  }

  // ===================== SNIPPETS =====================

  List<SnippetModel> getSnippets() {
    final raw = _prefs.getStringList(_snippetsKey);
    if (raw == null || raw.isEmpty) {
      // Default built-in snippets for quick DevOps productivity
      return [
        const SnippetModel(
          id: 'def_1',
          title: 'Docker PS',
          command: 'docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"',
          category: 'Docker',
        ),
        const SnippetModel(
          id: 'def_2',
          title: 'System Resource (htop)',
          command: 'htop',
          category: 'System',
        ),
        const SnippetModel(
          id: 'def_3',
          title: 'Disk Usage',
          command: 'df -h',
          category: 'System',
        ),
        const SnippetModel(
          id: 'def_4',
          title: 'Active Network Ports',
          command: 'ss -tulpn',
          category: 'Network',
        ),
        const SnippetModel(
          id: 'def_5',
          title: 'System Journal Logs',
          command: 'journalctl -xe -n 50 --no-pager',
          category: 'Logs',
        ),
      ];
    }
    return raw.map((item) => SnippetModel.fromJson(item)).toList();
  }

  Future<void> saveSnippet(SnippetModel snippet) async {
    final snippets = getSnippets();
    final index = snippets.indexWhere((s) => s.id == snippet.id);
    if (index >= 0) {
      snippets[index] = snippet;
    } else {
      snippets.add(snippet);
    }
    await _prefs.setStringList(
      _snippetsKey,
      snippets.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> deleteSnippet(String snippetId) async {
    final snippets = getSnippets();
    snippets.removeWhere((s) => s.id == snippetId);
    await _prefs.setStringList(
      _snippetsKey,
      snippets.map((s) => s.toJson()).toList(),
    );
  }

  // ===================== KNOWN HOSTS (MITM Protection) =====================

  Map<String, String> getKnownHosts() {
    final raw = _prefs.getString(_knownHostsKey);
    if (raw == null) return {};
    return Map<String, String>.from(json.decode(raw) as Map);
  }

  Future<void> addKnownHost(String hostKey, String fingerprint) async {
    final known = getKnownHosts();
    known[hostKey] = fingerprint;
    await _prefs.setString(_knownHostsKey, json.encode(known));
  }

  // ===================== SETTINGS =====================

  double getTerminalFontSize() {
    return _prefs.getDouble(_fontSizeKey) ?? 14.0;
  }

  Future<void> setTerminalFontSize(double size) async {
    await _prefs.setDouble(_fontSizeKey, size);
  }

  // ===================== LANGUAGE & UPDATES =====================

  String getLanguage() {
    return _prefs.getString(_languageKey) ?? 'zh'; // Default to Chinese as requested
  }

  Future<void> setLanguage(String lang) async {
    await _prefs.setString(_languageKey, lang);
  }

  bool getAutoCheckUpdates() {
    return _prefs.getBool(_autoUpdateKey) ?? true;
  }

  Future<void> setAutoCheckUpdates(bool enabled) async {
    await _prefs.setBool(_autoUpdateKey, enabled);
  }
}
