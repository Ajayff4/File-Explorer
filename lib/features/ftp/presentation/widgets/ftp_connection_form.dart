import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Add/edit form for an FTP/SFTP/FTPS connection. Returns validated
/// [FtpConnection] via [onSave]; id and timestamps preserved for edits.
class FtpConnectionForm extends StatefulWidget {
  const FtpConnectionForm({
    super.key,
    this.existing,
    required this.onSave,
  });

  final FtpConnection? existing;
  final ValueChanged<FtpConnection> onSave;

  @override
  State<FtpConnectionForm> createState() => _FtpConnectionFormState();
}

class _FtpConnectionFormState extends State<FtpConnectionForm> {
  final _formKey = GlobalKey<FormState>();
  late FtpProtocol _protocol;
  late SftpAuthType _sftpAuthType;
  late KeyFormat _keyFormat;
  String? _keyPath;
  late final TextEditingController _name;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _passphrase;
  late final TextEditingController _remotePath;
  late bool _passiveMode;
  late bool _acceptInvalidCert;
  bool _obscurePassword = true;

  bool get _usePrivateKey =>
      _protocol == FtpProtocol.sftp &&
      _sftpAuthType == SftpAuthType.privateKey;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _protocol = existing?.protocol ?? FtpProtocol.ftp;
    _sftpAuthType = existing?.sftpAuthType ?? SftpAuthType.password;
    _keyFormat = existing?.keyFormat ?? KeyFormat.auto;
    _keyPath = existing?.privateKeyPath;
    _name = TextEditingController(text: existing?.name ?? '');
    _host = TextEditingController(text: existing?.host ?? '');
    _port = TextEditingController(
      text: '${existing?.port ?? _protocol.defaultPort}',
    );
    _username = TextEditingController(text: existing?.username ?? '');
    _password = TextEditingController(text: existing?.password ?? '');
    _passphrase = TextEditingController(text: existing?.passphrase ?? '');
    _remotePath = TextEditingController(text: existing?.remotePath ?? '/');
    _passiveMode = existing?.passiveMode ?? true;
    _acceptInvalidCert = existing?.acceptInvalidCert ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    _passphrase.dispose();
    _remotePath.dispose();
    super.dispose();
  }

  void _onProtocolChanged(FtpProtocol? protocol) {
    if (protocol == null) return;
    setState(() {
      _protocol = protocol;
      _port.text = '${protocol.defaultPort}';
    });
  }

  Future<void> _pickKeyFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pem', 'key', 'ppk', 'openssh'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() {
      _keyPath = path;
      if (_keyFormat == KeyFormat.auto) {
        final lower = path.toLowerCase();
        if (lower.endsWith('.ppk')) {
          _keyFormat = KeyFormat.ppk;
        } else if (lower.endsWith('.pem')) {
          _keyFormat = KeyFormat.pem;
        }
      }
    });
  }

  void _submit() {
    if (_usePrivateKey && (_keyPath == null || _keyPath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Private key file is required')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final existing = widget.existing;
    final connection = FtpConnection(
      id: existing?.id ?? '${now.microsecondsSinceEpoch}',
      name: _name.text.trim(),
      protocol: _protocol,
      host: _host.text.trim(),
      port: int.parse(_port.text.trim()),
      username: _username.text.trim(),
      password: _usePrivateKey || _password.text.isEmpty ? null : _password.text,
      remotePath: _remotePath.text.isEmpty ? '/' : _remotePath.text.trim(),
      passiveMode: _passiveMode,
      acceptInvalidCert: _acceptInvalidCert,
      sftpAuthType: _protocol == FtpProtocol.sftp
          ? _sftpAuthType
          : SftpAuthType.password,
      privateKeyPath: _usePrivateKey ? _keyPath : null,
      keyFormat: _usePrivateKey ? _keyFormat : KeyFormat.auto,
      passphrase:
          _usePrivateKey && _passphrase.text.isNotEmpty ? _passphrase.text : null,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    widget.onSave(connection);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit connection' : 'New connection',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<FtpProtocol>(
                initialValue: _protocol,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final protocol in FtpProtocol.values)
                    DropdownMenuItem(
                      value: protocol,
                      child: Text(protocol.label),
                    ),
                ],
                onChanged: _onProtocolChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Home server',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _host,
                      decoration: const InputDecoration(
                        labelText: 'Host',
                        hintText: '192.168.1.10',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      validator: (value) =>
                          FtpConnection.validateHost(value ?? ''),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _port,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => FtpConnection.validatePort(
                        int.tryParse(value?.trim() ?? ''),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(
                  labelText: 'Username (empty = anonymous)',
                  border: OutlineInputBorder(),
                ),
                autocorrect: false,
                validator: (value) {
                  if (_usePrivateKey &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Username is required for key auth';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (_protocol == FtpProtocol.sftp) ...[
                DropdownButtonFormField<SftpAuthType>(
                  initialValue: _sftpAuthType,
                  decoration: const InputDecoration(
                    labelText: 'Authentication',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: SftpAuthType.password,
                      child: Text('Password'),
                    ),
                    DropdownMenuItem(
                      value: SftpAuthType.privateKey,
                      child: Text('Private key'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _sftpAuthType = value);
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (_usePrivateKey) ...[
                OutlinedButton.icon(
                  onPressed: _pickKeyFile,
                  icon: const Icon(Icons.key_rounded),
                  label: Text(
                    _keyPath == null
                        ? 'Select key file (.pem / .ppk / OpenSSH)'
                        : _keyPath!.split(RegExp(r'[/\\]')).last,
                  ),
                ),
                if (_keyPath == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Private key file is required',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<KeyFormat>(
                  initialValue: _keyFormat,
                  decoration: const InputDecoration(
                    labelText: 'Key format',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final format in KeyFormat.values)
                      DropdownMenuItem(
                        value: format,
                        child: Text(format.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _keyFormat = value);
                  },
                ),
                if (_keyFormat == KeyFormat.ppk)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'PPK needs export to OpenSSH (PuTTYgen > Conversions > Export OpenSSH key).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passphrase,
                  decoration: const InputDecoration(
                    labelText: 'Key passphrase (optional)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ] else
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: 'Password (optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'Show' : 'Hide',
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remotePath,
                decoration: const InputDecoration(
                  labelText: 'Remote path',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_protocol != FtpProtocol.sftp) ...[
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Passive mode'),
                  value: _passiveMode,
                  onChanged: (value) =>
                      setState(() => _passiveMode = value),
                ),
              ],
              if (_protocol == FtpProtocol.ftps)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Accept invalid certificate'),
                  subtitle: const Text('Only for self-signed servers'),
                  value: _acceptInvalidCert,
                  onChanged: (value) =>
                      setState(() => _acceptInvalidCert = value),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _submit,
                child: Text(isEdit ? 'Save' : 'Add connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
