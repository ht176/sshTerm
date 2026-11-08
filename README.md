# sshTerm 🚀

> A sleek, powerful, modern mobile SSH client inspired by Termius, built with Flutter, `dartssh2`, and `xterm.dart`.

[![Build & Release Android APK](https://github.com/ht176/sshTerm/actions/workflows/build.yml/badge.svg)](https://github.com/ht176/sshTerm/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## ✨ Features

- 🖥️ **Host Asset Management**:
  - Organize Linux, Cloud VPS, NAS, macOS servers with custom tags, groups, and color markers.
  - Support for custom SSH ports and username presets.
  - Connection history tracking.
- 🔑 **SSH Key Vault**:
  - In-app **Ed25519** and **RSA** (2048/4096-bit) key pair generation.
  - Import existing OpenSSH private keys (PEM format).
  - One-tap copy of OpenSSH public key for pasting into `~/.ssh/authorized_keys`.
  - Passphrase protection & Keychain/Keystore hardware-backed security.
- ⚡ **Mobile Terminal Experience**:
  - Ultra-smooth 60~120fps VT100 / xterm-256color rendering powered by `xterm.dart`.
  - **Mobile Keyboard Accessory Toolbar**:
    - Sticky `CTRL` & `ALT` toggles.
    - Dedicated `ESC`, `TAB`, Arrow Keys (`↑`, `↓`, `←`, `→`).
    - Quick UNIX signal buttons: `Ctrl+C` (SIGINT), `Ctrl+D` (EOF), `Ctrl+Z` (SUSP), `Ctrl+L` (Clear).
    - High-frequency shell symbols (`|`, `/`, `~`, `-`, `_`, `$`, `:`, `;`, `"`, `'`, `\`).
  - Font size on-the-fly adjustment.
  - Auto Keep-Alive pings to prevent socket drops on mobile networks.
- 🛡️ **Zero-Trust Host Verification**:
  - Known Hosts database.
  - SHA-256 host key fingerprint prompt on first connection to protect against MITM (Man-In-The-Middle) attacks.
- 💡 **DevOps Snippets**:
  - Save frequently used shell commands (Docker, systemctl, disk check, network ports) for one-tap execution in active sessions.

---

## 🛠️ Architecture & Tech Stack

```
sshTerm
├── UI (Flutter 3.47 / Material 3)
│   ├── Hosts Catalog & Grouping
│   ├── Terminal Screen (xterm.dart Canvas Engine)
│   ├── Mobile Keyboard Accessory Toolbar
│   └── Key Vault & Snippets
├── State Management
│   └── Riverpod 3.5 (Notifier & ProviderScope)
├── Core Network & SSH
│   └── dartssh2 4.1 (Pure Dart SSHv2 protocol stack)
└── Security & Storage
    ├── Flutter Secure Storage (iOS Keychain / Android Keystore)
    └── SharedPreferences (Encrypted settings & known hosts)
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.47.x or higher
- Dart SDK 3.13.x or higher

### Installation & Run

```bash
# Clone the repository
git clone https://github.com/ht176/sshTerm.git
cd sshTerm

# Install dependencies
flutter pub get

# Run test suite
flutter test

# Run app
flutter run
```

### Build Release Artifacts

```bash
# Build Android APK
flutter build apk --release

# Build Web application
flutter build web --release
```

---

## 🤖 CI / CD Pipeline

This project includes automated GitHub Actions (`.github/workflows/build.yml`):
- Automatically runs `flutter test` and `flutter analyze` on every commit.
- Builds release-ready Android APK (`app-release.apk`).
- Generates GitHub Releases with downloadable APK assets upon creating version tags (e.g. `git tag v1.0.0 && git push --tags`).
