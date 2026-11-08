import 'dart:convert';

enum KeyType {
  ed25519,
  rsa,
}

class SSHKeyPairModel {
  final String id;
  final String title;
  final KeyType keyType;
  final String publicKeyOpenSsh;
  final String privateKeyPem;
  final String fingerprint;
  final bool hasPassphrase;
  final DateTime createdAt;

  const SSHKeyPairModel({
    required this.id,
    required this.title,
    required this.keyType,
    required this.publicKeyOpenSsh,
    required this.privateKeyPem,
    required this.fingerprint,
    this.hasPassphrase = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'keyType': keyType.name,
      'publicKeyOpenSsh': publicKeyOpenSsh,
      'privateKeyPem': privateKeyPem,
      'fingerprint': fingerprint,
      'hasPassphrase': hasPassphrase,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SSHKeyPairModel.fromMap(Map<String, dynamic> map) {
    return SSHKeyPairModel(
      id: map['id'] as String,
      title: map['title'] as String,
      keyType: KeyType.values.firstWhere(
        (e) => e.name == map['keyType'],
        orElse: () => KeyType.ed25519,
      ),
      publicKeyOpenSsh: map['publicKeyOpenSsh'] as String,
      privateKeyPem: map['privateKeyPem'] as String,
      fingerprint: map['fingerprint'] as String? ?? '',
      hasPassphrase: map['hasPassphrase'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory SSHKeyPairModel.fromJson(String source) =>
      SSHKeyPairModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
