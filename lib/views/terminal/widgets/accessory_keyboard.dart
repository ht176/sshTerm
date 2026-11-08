import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

import '../../../core/theme/app_theme.dart';

class TerminalAccessoryController with ChangeNotifier {
  final Terminal terminal;
  final void Function(String text)? onSendRaw;
  final VoidCallback? onOpenSnippets;

  bool _ctrl = false;
  bool _alt = false;
  bool _shift = false;

  TerminalAccessoryController({
    required this.terminal,
    this.onSendRaw,
    this.onOpenSnippets,
  });

  bool get ctrl => _ctrl;
  bool get alt => _alt;
  bool get shift => _shift;

  void toggleCtrl() {
    _ctrl = !_ctrl;
    notifyListeners();
  }

  void toggleAlt() {
    _alt = !_alt;
    notifyListeners();
  }

  void toggleShift() {
    _shift = !_shift;
    notifyListeners();
  }

  void resetModifiers() {
    if (_ctrl || _alt || _shift) {
      _ctrl = false;
      _alt = false;
      _shift = false;
      notifyListeners();
    }
  }

  void sendString(String text) {
    HapticFeedback.lightImpact();
    if (onSendRaw != null) {
      onSendRaw!(text);
    } else {
      terminal.write(text);
    }
  }

  // Common ANSI escape sequences
  void sendEsc() => sendString('\x1b');
  void sendTab() => sendString('\t');
  void sendArrowUp() => sendString('\x1b[A');
  void sendArrowDown() => sendString('\x1b[B');
  void sendArrowRight() => sendString('\x1b[C');
  void sendArrowLeft() => sendString('\x1b[D');
  void sendHome() => sendString('\x1b[H');
  void sendEnd() => sendString('\x1b[F');
  void sendPageUp() => sendString('\x1b[5~');
  void sendPageDown() => sendString('\x1b[6~');

  // Quick signals
  void sendCtrlC() {
    sendString('\x03');
    resetModifiers();
  }

  void sendCtrlD() {
    sendString('\x04');
    resetModifiers();
  }

  void sendCtrlZ() {
    sendString('\x1a');
    resetModifiers();
  }

  void sendCtrlL() {
    sendString('\x0c');
    resetModifiers();
  }
}

class TerminalAccessoryBar extends StatelessWidget {
  final TerminalAccessoryController controller;

  const TerminalAccessoryBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          height: 44,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceElevated,
            border: Border(
              top: BorderSide(color: AppTheme.surfaceBorder, width: 0.8),
            ),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            children: [
              // Modifiers
              _buildKey(
                label: 'ESC',
                onTap: controller.sendEsc,
                highlight: false,
              ),
              _buildKey(
                label: 'TAB',
                onTap: controller.sendTab,
                highlight: false,
              ),
              _buildKey(
                label: 'CTRL',
                onTap: controller.toggleCtrl,
                highlight: controller.ctrl,
                activeColor: AppTheme.primary,
              ),
              _buildKey(
                label: 'ALT',
                onTap: controller.toggleAlt,
                highlight: controller.alt,
                activeColor: AppTheme.accentPurple,
              ),

              const _KeyDivider(),

              // Quick Interrupts
              _buildKey(
                label: '^C',
                onTap: controller.sendCtrlC,
                tooltip: 'Interrupt (SIGINT)',
                textColor: AppTheme.accentRed,
              ),
              _buildKey(
                label: '^D',
                onTap: controller.sendCtrlD,
                tooltip: 'EOF / Logout',
              ),
              _buildKey(
                label: '^L',
                onTap: controller.sendCtrlL,
                tooltip: 'Clear Screen',
              ),
              _buildKey(
                label: '^Z',
                onTap: controller.sendCtrlZ,
                tooltip: 'Suspend Process',
              ),

              const _KeyDivider(),

              // Direction Arrows
              _buildIconKey(
                icon: Icons.arrow_upward_rounded,
                onTap: controller.sendArrowUp,
              ),
              _buildIconKey(
                icon: Icons.arrow_downward_rounded,
                onTap: controller.sendArrowDown,
              ),
              _buildIconKey(
                icon: Icons.arrow_back_rounded,
                onTap: controller.sendArrowLeft,
              ),
              _buildIconKey(
                icon: Icons.arrow_forward_rounded,
                onTap: controller.sendArrowRight,
              ),

              const _KeyDivider(),

              // Quick Symbols
              _buildKey(label: '|', onTap: () => controller.sendString('|')),
              _buildKey(label: '/', onTap: () => controller.sendString('/')),
              _buildKey(label: '~', onTap: () => controller.sendString('~')),
              _buildKey(label: '-', onTap: () => controller.sendString('-')),
              _buildKey(label: '_', onTap: () => controller.sendString('_')),
              _buildKey(label: ':', onTap: () => controller.sendString(':')),
              _buildKey(label: ';', onTap: () => controller.sendString(';')),
              _buildKey(label: r'$', onTap: () => controller.sendString(r'$')),
              _buildKey(label: '"', onTap: () => controller.sendString('"')),
              _buildKey(label: "'", onTap: () => controller.sendString("'")),
              _buildKey(label: '`', onTap: () => controller.sendString('`')),
              _buildKey(label: r'\', onTap: () => controller.sendString(r'\')),

              if (controller.onOpenSnippets != null) ...[
                const _KeyDivider(),
                _buildActionKey(
                  icon: Icons.bolt_rounded,
                  label: 'Snippets',
                  onTap: controller.onOpenSnippets!,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildKey({
    required String label,
    required VoidCallback onTap,
    bool highlight = false,
    Color? activeColor,
    Color? textColor,
    String? tooltip,
  }) {
    final bg = highlight ? (activeColor ?? AppTheme.primary) : AppTheme.surface;
    final fg = highlight
        ? Colors.white
        : (textColor ?? AppTheme.textPrimary);

    final button = Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 36),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: highlight
                    ? (activeColor ?? AppTheme.primary)
                    : AppTheme.surfaceBorder,
                width: 0.8,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  Widget _buildIconKey({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 34),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.surfaceBorder, width: 0.8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: AppTheme.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppTheme.primaryLight),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyDivider extends StatelessWidget {
  const _KeyDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      color: AppTheme.surfaceBorder,
    );
  }
}
