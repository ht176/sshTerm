import 'package:flutter_test/flutter_test.dart';
import 'package:ssh_term/models/ssh_host.dart';
import 'package:ssh_term/services/key_service.dart';

void main() {
  test('SSH Host serialization test', () {
    const host = SSHHost(
      id: 'test_1',
      label: 'NAS Server',
      hostname: '192.168.1.100',
      username: 'root',
    );

    final jsonStr = host.toJson();
    final decoded = SSHHost.fromJson(jsonStr);

    expect(decoded.id, 'test_1');
    expect(decoded.label, 'NAS Server');
    expect(decoded.hostname, '192.168.1.100');
    expect(decoded.port, 22);
    expect(decoded.username, 'root');
    expect(decoded.authType, AuthType.password);
  });

  test('Ed25519 Key Generation test', () {
    final key = KeyService.generateEd25519(title: 'Unit Test Key');
    expect(key.title, 'Unit Test Key');
    expect(key.publicKeyOpenSsh.startsWith('ssh-ed25519 '), isTrue);
    expect(key.privateKeyPem.contains('BEGIN OPENSSH PRIVATE KEY'), isTrue);
    expect(key.fingerprint.startsWith('SHA256:'), isTrue);
  });
}
