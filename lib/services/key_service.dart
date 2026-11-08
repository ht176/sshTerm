import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dartssh2/dartssh2.dart';
import 'package:pinenacl/ed25519.dart' as pinenacl;
import 'package:pointycastle/export.dart' as pc;
import 'package:uuid/uuid.dart';

import '../models/ssh_key_pair_model.dart';

class KeyService {
  static final _uuid = const Uuid();

  /// Formats an [SSHHostKey] to standard OpenSSH line format
  /// e.g. "ssh-ed25519 AAAAC3... user@host"
  static String formatOpenSsh(SSHHostKey hostKey, String comment) {
    final encoded = hostKey.encode();
    final type = SSHHostKey.getType(encoded);
    final b64 = base64.encode(encoded);
    return '$type $b64 $comment'.trim();
  }

  /// Generate an Ed25519 key pair
  static SSHKeyPairModel generateEd25519({
    required String title,
    String? comment,
    String? passphrase,
  }) {
    final effectiveComment = comment ?? '$title@sshTerm';
    final signingKey = pinenacl.SigningKey.generate();
    final privateKeyBytes = signingKey.asTypedList;
    final publicKeyBytes = signingKey.verifyKey.asTypedList;

    final keyPair = OpenSSHEd25519KeyPair(
      publicKeyBytes,
      privateKeyBytes,
      effectiveComment,
    );

    final privatePem = keyPair.toPem(passphrase: passphrase);
    final hostKey = keyPair.toPublicKey();
    final publicOpenSsh = formatOpenSsh(hostKey, effectiveComment);
    final fingerprint = _calculateFingerprint(hostKey.encode());

    return SSHKeyPairModel(
      id: _uuid.v4(),
      title: title,
      keyType: KeyType.ed25519,
      publicKeyOpenSsh: publicOpenSsh,
      privateKeyPem: privatePem,
      fingerprint: fingerprint,
      hasPassphrase: passphrase != null && passphrase.isNotEmpty,
      createdAt: DateTime.now(),
    );
  }

  /// Generate an RSA key pair (2048 or 4096 bit)
  static SSHKeyPairModel generateRsa({
    required String title,
    int bitLength = 2048,
    String? comment,
    String? passphrase,
  }) {
    final effectiveComment = comment ?? '$title@sshTerm';

    // Set up PointyCastle secure random & RSA generator
    final secureRandom = _getSecureRandom();
    final keyGen = pc.RSAKeyGenerator()
      ..init(
        pc.ParametersWithRandom(
          pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
          secureRandom,
        ),
      );

    final pair = keyGen.generateKeyPair();
    final privateKey = pair.privateKey;
    final publicKey = pair.publicKey;

    final n = publicKey.modulus!;
    final e = publicKey.publicExponent!;
    final d = privateKey.privateExponent!;
    final p = privateKey.p!;
    final q = privateKey.q!;
    final iqmp = q.modInverse(p);

    final keyPair = OpenSSHRsaKeyPair(
      n,
      e,
      d,
      iqmp,
      p,
      q,
      effectiveComment,
    );

    final privatePem = keyPair.toPem(passphrase: passphrase);
    final hostKey = keyPair.toPublicKey();
    final publicOpenSsh = formatOpenSsh(hostKey, effectiveComment);
    final fingerprint = _calculateFingerprint(hostKey.encode());

    return SSHKeyPairModel(
      id: _uuid.v4(),
      title: title,
      keyType: KeyType.rsa,
      publicKeyOpenSsh: publicOpenSsh,
      privateKeyPem: privatePem,
      fingerprint: fingerprint,
      hasPassphrase: passphrase != null && passphrase.isNotEmpty,
      createdAt: DateTime.now(),
    );
  }

  /// Import key pair from PEM text
  static SSHKeyPairModel importFromPem({
    required String title,
    required String pemText,
    String? passphrase,
  }) {
    final identities = SSHKeyPair.fromPem(pemText, passphrase);
    if (identities.isEmpty) {
      throw FormatException('No valid SSH private keys found in the provided text.');
    }

    final identity = identities.first;
    KeyType keyType = KeyType.rsa;
    if (identity is OpenSSHEd25519KeyPair) {
      keyType = KeyType.ed25519;
    }

    final hostKey = identity.toPublicKey();
    final publicOpenSsh = formatOpenSsh(hostKey, identity.comment ?? title);
    final fingerprint = _calculateFingerprint(hostKey.encode());

    return SSHKeyPairModel(
      id: _uuid.v4(),
      title: title,
      keyType: keyType,
      publicKeyOpenSsh: publicOpenSsh,
      privateKeyPem: pemText,
      fingerprint: fingerprint,
      hasPassphrase: passphrase != null && passphrase.isNotEmpty,
      createdAt: DateTime.now(),
    );
  }

  /// Calculates SHA-256 fingerprint from public key wire bytes
  static String _calculateFingerprint(Uint8List keyBytes) {
    final digest = crypto.sha256.convert(keyBytes);
    final base64Hash = base64Url.encode(digest.bytes).replaceAll('=', '');
    return 'SHA256:$base64Hash';
  }

  static pc.SecureRandom _getSecureRandom() {
    final secureRandom = pc.FortunaRandom();
    final random = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(255));
    }
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }
}
