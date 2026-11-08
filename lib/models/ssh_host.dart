import 'dart:convert';

enum AuthType {
  password,
  key,
}

class SSHHost {
  final String id;
  final String label;
  final String hostname;
  final int port;
  final String username;
  final AuthType authType;
  final String? keyId; // ID of the SSHKeyPairModel if authType == key
  final String group;
  final String colorHex;
  final String? osIcon; // e.g. 'ubuntu', 'debian', 'centos', 'arch', 'apple', 'server'
  final DateTime? lastConnectedAt;

  const SSHHost({
    required this.id,
    required this.label,
    required this.hostname,
    this.port = 22,
    required this.username,
    this.authType = AuthType.password,
    this.keyId,
    this.group = 'Default',
    this.colorHex = '#4E75FF',
    this.osIcon = 'server',
    this.lastConnectedAt,
  });

  SSHHost copyWith({
    String? id,
    String? label,
    String? hostname,
    int? port,
    String? username,
    AuthType? authType,
    String? keyId,
    String? group,
    String? colorHex,
    String? osIcon,
    DateTime? lastConnectedAt,
  }) {
    return SSHHost(
      id: id ?? this.id,
      label: label ?? this.label,
      hostname: hostname ?? this.hostname,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      keyId: keyId ?? this.keyId,
      group: group ?? this.group,
      colorHex: colorHex ?? this.colorHex,
      osIcon: osIcon ?? this.osIcon,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'hostname': hostname,
      'port': port,
      'username': username,
      'authType': authType.name,
      'keyId': keyId,
      'group': group,
      'colorHex': colorHex,
      'osIcon': osIcon,
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
    };
  }

  factory SSHHost.fromMap(Map<String, dynamic> map) {
    return SSHHost(
      id: map['id'] as String,
      label: map['label'] as String,
      hostname: map['hostname'] as String,
      port: map['port'] as int? ?? 22,
      username: map['username'] as String,
      authType: AuthType.values.firstWhere(
        (e) => e.name == map['authType'],
        orElse: () => AuthType.password,
      ),
      keyId: map['keyId'] as String?,
      group: map['group'] as String? ?? 'Default',
      colorHex: map['colorHex'] as String? ?? '#4E75FF',
      osIcon: map['osIcon'] as String? ?? 'server',
      lastConnectedAt: map['lastConnectedAt'] != null
          ? DateTime.parse(map['lastConnectedAt'] as String)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory SSHHost.fromJson(String source) =>
      SSHHost.fromMap(json.decode(source) as Map<String, dynamic>);
}
