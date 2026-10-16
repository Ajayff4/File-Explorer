/// FTP connection entities (FTP / SFTP / FTPS).
library;

/// Supported remote connection types.
enum FtpProtocol {
  ftp,
  sftp,
  ftps;

  /// Default network port for the protocol.
  int get defaultPort => switch (this) {
        FtpProtocol.ftp => 21,
        FtpProtocol.sftp => 22,
        FtpProtocol.ftps => 990,
      };

  /// Uppercase label for UI.
  String get label => switch (this) {
        FtpProtocol.ftp => 'FTP',
        FtpProtocol.sftp => 'SFTP',
        FtpProtocol.ftps => 'FTPS',
      };

  static FtpProtocol fromName(String? name) {
    return FtpProtocol.values.firstWhere(
      (protocol) => protocol.name == name,
      orElse: () => FtpProtocol.ftp,
    );
  }
}

/// How an SFTP connection authenticates. FTP/FTPS always use password.
enum SftpAuthType {
  password,
  privateKey;
}

/// On-disk format of the SFTP private key file. `auto` sniffs from content
/// (`PuTTY-User-Key-File` = PPK, `-----BEGIN` = PEM/OpenSSH).
enum KeyFormat {
  auto,
  openssh,
  pem,
  ppk;

  String get label => switch (this) {
        KeyFormat.auto => 'Auto-detect',
        KeyFormat.openssh => 'OpenSSH',
        KeyFormat.pem => 'PEM',
        KeyFormat.ppk => 'PPK (PuTTY)',
      };

  static KeyFormat sniff(String content) {
    if (content.contains('PuTTY-User-Key-File')) return KeyFormat.ppk;
    if (content.contains('-----BEGIN')) {
      return content.contains('OPENSSH') ? KeyFormat.openssh : KeyFormat.pem;
    }
    return KeyFormat.auto;
  }
}

/// A saved remote server connection. Password stays nullable and empty
/// means anonymous login (FTP/FTPS). SFTP with [SftpAuthType.privateKey]
/// uses the key file at [privateKeyPath] plus optional [passphrase].
class FtpConnection {
  const FtpConnection({
    required this.id,
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    required this.username,
    required this.createdAt,
    required this.updatedAt,
    this.password,
    this.remotePath = '/',
    this.passiveMode = true,
    this.acceptInvalidCert = false,
    this.sftpAuthType = SftpAuthType.password,
    this.privateKeyPath,
    this.keyFormat = KeyFormat.auto,
    this.passphrase,
  });

  final String id;
  final String name;
  final FtpProtocol protocol;
  final String host;
  final int port;
  final String username;
  final String? password;
  final String remotePath;
  final bool passiveMode;
  final bool acceptInvalidCert;
  final SftpAuthType sftpAuthType;
  final String? privateKeyPath;
  final KeyFormat keyFormat;
  final String? passphrase;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// First validation error, or null when valid.
  String? validate() {
    if (name.trim().isEmpty) return 'Name is required';
    final hostError = validateHost(host);
    if (hostError != null) return hostError;
    final portError = validatePort(port);
    if (portError != null) return portError;
    if (remotePath.isEmpty) return 'Remote path is required';
    if (protocol == FtpProtocol.sftp &&
        sftpAuthType == SftpAuthType.privateKey) {
      if (username.trim().isEmpty) return 'Username is required for key auth';
      if (privateKeyPath == null || privateKeyPath!.trim().isEmpty) {
        return 'Private key file is required';
      }
    }
    return null;
  }

  static String? validateHost(String value) {
    final host = value.trim();
    if (host.isEmpty) return 'Host is required';
    if (host.contains(' ')) return 'Host must not contain spaces';
    if (host.contains('://')) return 'Host must not include ://';
    if (host.length > 253) return 'Host is too long';
    return null;
  }

  static String? validatePort(int? value) {
    if (value == null) return 'Port is required';
    if (value < 1 || value > 65535) return 'Port must be 1-65535';
    return null;
  }

  static int parsePort(String value, {required FtpProtocol protocol}) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return protocol.defaultPort;
    if (parsed < 1 || parsed > 65535) return protocol.defaultPort;
    return parsed;
  }

  /// Human-readable `host:port` for list tiles.
  String get address => '$host:$port';

  /// True when this connection logs in with an SSH private key.
  bool get usesPrivateKey =>
      protocol == FtpProtocol.sftp &&
      sftpAuthType == SftpAuthType.privateKey;

  /// File name of the key for list tiles, null when no key set.
  String? get privateKeyFileName {
    final path = privateKeyPath;
    if (path == null || path.isEmpty) return null;
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.isEmpty ? path : parts.last;
  }

  FtpConnection copyWith({
    String? name,
    FtpProtocol? protocol,
    String? host,
    int? port,
    String? username,
    String? Function()? password,
    String? remotePath,
    bool? passiveMode,
    bool? acceptInvalidCert,
    SftpAuthType? sftpAuthType,
    String? Function()? privateKeyPath,
    KeyFormat? keyFormat,
    String? Function()? passphrase,
    DateTime? updatedAt,
  }) {
    return FtpConnection(
      id: id,
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password == null ? this.password : password(),
      remotePath: remotePath ?? this.remotePath,
      passiveMode: passiveMode ?? this.passiveMode,
      acceptInvalidCert: acceptInvalidCert ?? this.acceptInvalidCert,
      sftpAuthType: sftpAuthType ?? this.sftpAuthType,
      privateKeyPath:
          privateKeyPath == null ? this.privateKeyPath : privateKeyPath(),
      keyFormat: keyFormat ?? this.keyFormat,
      passphrase: passphrase == null ? this.passphrase : passphrase(),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
