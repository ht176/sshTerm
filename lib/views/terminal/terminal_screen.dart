import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ssh_host.dart';
import '../../providers/app_providers.dart';
import '../../services/ssh_service.dart';
import 'widgets/accessory_keyboard.dart';
import 'widgets/fingerprint_dialog.dart';

enum ConnectionState {
  connecting,
  connected,
  disconnected,
  error,
}

class TerminalScreen extends ConsumerStatefulWidget {
  final SSHHost host;

  const TerminalScreen({super.key, required this.host});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  late final Terminal _terminal;
  late final TerminalAccessoryController _accessoryController;
  final StringBuffer _terminalLogBuffer = StringBuffer();
  String? _lastErrorDetails;
  SSHConnectionSession? _session;
  ConnectionState _connectionState = ConnectionState.connecting;
  String _statusMessage = 'Connecting...';
  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(
      maxLines: 5000,
    );

    _accessoryController = TerminalAccessoryController(
      terminal: _terminal,
      onSendRaw: (text) {
        if (_session != null) {
          _session!.session.write(Uint8List.fromList(utf8.encode(text)));
        }
      },
      onOpenSnippets: _showSnippetsSheet,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startConnection();
    });
  }

  @override
  void dispose() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _session?.close();
    super.dispose();
  }

  void _appendLog(String text) {
    _terminal.write(text);
    // Strip ANSI escape codes for clean clipboard text
    final clean = text.replaceAll(RegExp(r'\x1b\[[0-9;]*[a-zA-Z]'), '');
    _terminalLogBuffer.write(clean);
  }

  Future<void> _startConnection() async {
    final strings = ref.read(stringsProvider);

    setState(() {
      _connectionState = ConnectionState.connecting;
      _lastErrorDetails = null;
      _statusMessage = strings.connectingTo(widget.host.username, widget.host.hostname, widget.host.port);
    });

    _appendLog('\x1b[38;5;39m[sshTerm] $_statusMessage\x1b[0m\r\n');

    try {
      final storage = ref.read(storageServiceProvider);

      // Load credentials
      String? password;
      String? privateKeyPem;
      String? keyPassphrase;

      if (widget.host.authType == AuthType.password) {
        password = await storage.getHostPassword(widget.host.id);
      } else if (widget.host.keyId != null) {
        privateKeyPem = await storage.getPrivateKeyPem(widget.host.keyId!);
        keyPassphrase = await storage.getKeyPassphrase(widget.host.keyId!);
      }

      final session = await SSHService.connect(
        host: widget.host,
        password: password,
        privateKeyPem: privateKeyPem,
        keyPassphrase: keyPassphrase,
        terminalWidth: _terminal.viewWidth > 0 ? _terminal.viewWidth : 80,
        terminalHeight: _terminal.viewHeight > 0 ? _terminal.viewHeight : 24,
        onVerifyHostKey: (host, port, keyType, fingerprint) async {
          final knownHosts = storage.getKnownHosts();
          final hostKey = '$host:$port';

          if (knownHosts.containsKey(hostKey)) {
            // Already verified before
            return knownHosts[hostKey] == fingerprint;
          }

          if (!mounted) return false;

          // Prompt user to verify host key
          final trusted = await FingerprintDialog.show(
            context,
            hostname: host,
            port: port,
            keyType: keyType,
            fingerprint: fingerprint,
            strings: strings,
          );

          if (trusted) {
            await storage.addKnownHost(hostKey, fingerprint);
            return true;
          }
          return false;
        },
      );

      _session = session;

      if (!mounted) {
        session.close();
        return;
      }

      setState(() {
        _connectionState = ConnectionState.connected;
        _statusMessage = strings.connected;
      });

      _appendLog('\x1b[38;5;48m[sshTerm] ${strings.connected}.\x1b[0m\r\n\r\n');

      // Update last connected timestamp
      ref.read(hostsProvider.notifier).updateLastConnected(widget.host.id);

      // Listen to output and terminal resize
      _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        try {
          session.session.resizeTerminal(width, height, pixelWidth, pixelHeight);
        } catch (_) {}
      };

      _terminal.onOutput = (data) {
        session.session.write(Uint8List.fromList(utf8.encode(data)));
      };

      _stdoutSub = session.session.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(
            (data) => _appendLog(data),
            onError: (err) => _onSessionClosed('Stream error: $err'),
            onDone: () => _onSessionClosed('Session closed.'),
          );

      _stderrSub = session.session.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(
            (data) => _appendLog(data),
            onError: (err) => _onSessionClosed('Stream error: $err'),
            onDone: () => _onSessionClosed('Session closed.'),
          );
    } catch (e, stack) {
      if (!mounted) return;
      final errorStr = e.toString();
      setState(() {
        _connectionState = ConnectionState.error;
        _statusMessage = errorStr;
        _lastErrorDetails = '$errorStr\n\nStack Trace:\n$stack';
      });
      _appendLog('\r\n\x1b[38;5;196m[sshTerm Error] $e\x1b[0m\r\n');
    }
  }

  void _onSessionClosed(String reason) {
    if (!mounted) return;
    final strings = ref.read(stringsProvider);
    setState(() {
      _connectionState = ConnectionState.disconnected;
      _statusMessage = strings.disconnected;
    });
    _appendLog('\r\n\x1b[38;5;214m[sshTerm] $reason\x1b[0m\r\n');
  }

  void _reconnect() {
    _session?.close();
    _terminal.buffer.clear();
    _terminal.buffer.setCursor(0, 0);
    _terminalLogBuffer.clear();
    _startConnection();
  }

  void _copyErrorToClipboard() {
    final strings = ref.read(stringsProvider);
    final text = _lastErrorDetails ?? _statusMessage;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.errorCopied),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _copyAllLogsToClipboard() {
    final strings = ref.read(stringsProvider);
    final text = _terminalLogBuffer.toString();
    Clipboard.setData(ClipboardData(text: text.isNotEmpty ? text : _statusMessage));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.terminalLogCopied),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _showErrorDetailsDialog() {
    final strings = ref.read(stringsProvider);
    final details = _lastErrorDetails ?? _statusMessage;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.accentRed),
            const SizedBox(width: 8),
            Text(strings.errorDetails),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: SelectableText(
                  details,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.close),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(strings.copyError),
            onPressed: () {
              Navigator.pop(ctx);
              _copyErrorToClipboard();
            },
          ),
        ],
      ),
    );
  }

  void _showSnippetsSheet() {
    final strings = ref.read(stringsProvider);
    final snippets = ref.read(snippetsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.snippetsDrawer,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.surfaceBorder),
                if (snippets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        strings.noSnippetsYet,
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: snippets.length,
                      itemBuilder: (context, index) {
                        final s = snippets[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: AppTheme.primaryLight,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            s.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            s.command,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: AppTheme.primaryLight,
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _accessoryController.sendString('${s.command}\n');
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final currentFontSize = ref.watch(fontSizeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF101216),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14171E),
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.host.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusDot(),
              ],
            ),
            Text(
              '${widget.host.username}@${widget.host.hostname}:${widget.host.port}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          // Copy logs action
          IconButton(
            icon: const Icon(Icons.copy_all_rounded, size: 20),
            tooltip: strings.copyTerminalLog,
            onPressed: _copyAllLogsToClipboard,
          ),
          // Font size quick adjustment
          IconButton(
            icon: const Icon(Icons.text_decrease_rounded, size: 20),
            tooltip: strings.decreaseFont,
            onPressed: () {
              if (currentFontSize > 10) {
                ref.read(fontSizeProvider.notifier).setFontSize(currentFontSize - 1);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_increase_rounded, size: 20),
            tooltip: strings.increaseFont,
            onPressed: () {
              if (currentFontSize < 24) {
                ref.read(fontSizeProvider.notifier).setFontSize(currentFontSize + 1);
              }
            },
          ),
          if (_connectionState != ConnectionState.connected)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryLight),
              tooltip: strings.reconnect,
              onPressed: _reconnect,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar banner when disconnected or error
            if (_connectionState != ConnectionState.connected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: _connectionState == ConnectionState.connecting
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.accentRed.withValues(alpha: 0.2),
                child: Row(
                  children: [
                    if (_connectionState == ConnectionState.connecting)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.accentRed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _connectionState == ConnectionState.error ? _showErrorDetailsDialog : null,
                        child: Text(
                          _statusMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                        ),
                      ),
                    ),
                    if (_connectionState == ConnectionState.error) ...[
                      const SizedBox(width: 8),
                      // Copy Error Button
                      InkWell(
                        onTap: _copyErrorToClipboard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.copy_rounded, size: 12, color: AppTheme.primaryLight),
                              const SizedBox(width: 4),
                              Text(
                                strings.copyError,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_connectionState != ConnectionState.connecting) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _reconnect,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            strings.retry,
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Terminal View
            Expanded(
              child: Container(
                color: const Color(0xFF0F1117),
                child: TerminalView(
                  _terminal,
                  textStyle: TerminalStyle(
                    fontSize: currentFontSize,
                    fontFamily: 'monospace',
                  ),
                  theme: TerminalThemes.defaultTheme,
                  autofocus: true,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),

            // Floating Accessory Bar (above keyboard)
            TerminalAccessoryBar(controller: _accessoryController),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot() {
    Color color;
    switch (_connectionState) {
      case ConnectionState.connecting:
        color = AppTheme.accentOrange;
        break;
      case ConnectionState.connected:
        color = AppTheme.accentGreen;
        break;
      case ConnectionState.disconnected:
        color = AppTheme.textMuted;
        break;
      case ConnectionState.error:
        color = AppTheme.accentRed;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
