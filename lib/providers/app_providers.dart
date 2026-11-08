import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/snippet_model.dart';
import '../models/ssh_host.dart';
import '../models/ssh_key_pair_model.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized before runApp');
});

// ===================== HOSTS =====================

class HostsNotifier extends Notifier<List<SSHHost>> {
  @override
  List<SSHHost> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getHosts();
  }

  Future<void> addOrUpdateHost(SSHHost host, {String? password}) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveHost(host, password: password);
    state = storage.getHosts();
  }

  Future<void> deleteHost(String hostId) async {
    final storage = ref.read(storageServiceProvider);
    await storage.deleteHost(hostId);
    state = storage.getHosts();
  }

  Future<void> updateLastConnected(String hostId) async {
    final storage = ref.read(storageServiceProvider);
    final hosts = storage.getHosts();
    final index = hosts.indexWhere((h) => h.id == hostId);
    if (index >= 0) {
      final updated = hosts[index].copyWith(lastConnectedAt: DateTime.now());
      await storage.saveHost(updated);
      state = storage.getHosts();
    }
  }
}

final hostsProvider = NotifierProvider<HostsNotifier, List<SSHHost>>(
  HostsNotifier.new,
);

// Host group filter (e.g. 'All', 'Default', etc.)
class SelectedGroupNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setGroup(String group) => state = group;
}

final selectedGroupProvider = NotifierProvider<SelectedGroupNotifier, String>(
  SelectedGroupNotifier.new,
);

// ===================== KEYS =====================

class KeyPairsNotifier extends Notifier<List<SSHKeyPairModel>> {
  @override
  List<SSHKeyPairModel> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getKeyPairs();
  }

  Future<void> addOrUpdateKey(SSHKeyPairModel key, {String? passphrase}) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveKeyPair(key, passphrase: passphrase);
    state = storage.getKeyPairs();
  }

  Future<void> deleteKey(String keyId) async {
    final storage = ref.read(storageServiceProvider);
    await storage.deleteKeyPair(keyId);
    state = storage.getKeyPairs();
  }
}

final keyPairsProvider = NotifierProvider<KeyPairsNotifier, List<SSHKeyPairModel>>(
  KeyPairsNotifier.new,
);

// ===================== SNIPPETS =====================

class SnippetsNotifier extends Notifier<List<SnippetModel>> {
  @override
  List<SnippetModel> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getSnippets();
  }

  Future<void> addOrUpdateSnippet(SnippetModel snippet) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveSnippet(snippet);
    state = storage.getSnippets();
  }

  Future<void> deleteSnippet(String snippetId) async {
    final storage = ref.read(storageServiceProvider);
    await storage.deleteSnippet(snippetId);
    state = storage.getSnippets();
  }
}

final snippetsProvider = NotifierProvider<SnippetsNotifier, List<SnippetModel>>(
  SnippetsNotifier.new,
);

// ===================== SETTINGS =====================

class FontSizeNotifier extends Notifier<double> {
  @override
  double build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getTerminalFontSize();
  }

  void setFontSize(double size) {
    state = size;
    ref.read(storageServiceProvider).setTerminalFontSize(size);
  }
}

final fontSizeProvider = NotifierProvider<FontSizeNotifier, double>(
  FontSizeNotifier.new,
);
