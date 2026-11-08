import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';

import '../models/ssh_host.dart';

typedef HostKeyVerificationCallback = Future<bool> Function(
  String host,
  int port,
  String keyType,
  String fingerprint,
);

class SSHConnectionSession {
  final SSHClient client;
  final SSHSession session;
  final SSHSocket socket;
  Timer? keepAliveTimer;

  SSHConnectionSession({
    required this.client,
    required this.session,
    required this.socket,
  });

  void startKeepAlive({Duration interval = const Duration(seconds: 30)}) {
    keepAliveTimer?.cancel();
    keepAliveTimer = Timer.periodic(interval, (_) async {
      try {
        await client.ping();
      } catch (_) {
        // Socket closed or dead
      }
    });
  }

  void close() {
    keepAliveTimer?.cancel();
    keepAliveTimer = null;
    try {
      session.close();
    } catch (_) {}
    try {
      client.close();
    } catch (_) {}
  }
}

class SSHService {
  /// Connects to an SSH host and spawns a PTY shell session
  static Future<SSHConnectionSession> connect({
    required SSHHost host,
    String? password,
    String? privateKeyPem,
    String? keyPassphrase,
    required int terminalWidth,
    required int terminalHeight,
    HostKeyVerificationCallback? onVerifyHostKey,
  }) async {
    final socket = await SSHSocket.connect(
      host.hostname,
      host.port,
      timeout: const Duration(seconds: 15),
    );

    // Prepare identities if key auth is used
    List<SSHKeyPair>? identities;
    if (host.authType == AuthType.key && privateKeyPem != null) {
      identities = SSHKeyPair.fromPem(privateKeyPem, keyPassphrase);
    }

    final client = SSHClient(
      socket,
      username: host.username,
      onPasswordRequest: () => password ?? '',
      identities: identities,
      onVerifyHostKey: (type, fingerprintBytes) async {
        final fpString = utf8.decode(fingerprintBytes);
        if (onVerifyHostKey != null) {
          return await onVerifyHostKey(host.hostname, host.port, type, fpString);
        }
        return true;
      },
    );

    // Request PTY shell
    final session = await client.shell(
      pty: SSHPtyConfig(
        width: terminalWidth > 0 ? terminalWidth : 80,
        height: terminalHeight > 0 ? terminalHeight : 24,
        type: 'xterm-256color',
      ),
    );

    final connection = SSHConnectionSession(
      client: client,
      session: session,
      socket: socket,
    );

    connection.startKeepAlive();
    return connection;
  }
}
