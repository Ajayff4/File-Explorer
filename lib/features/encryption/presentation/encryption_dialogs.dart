import 'package:flutter/material.dart';

class EncryptOptions {
  const EncryptOptions({required this.password, required this.encryptName});

  final String password;
  final bool encryptName;
}

/// Shows the encryption dialog and returns the chosen options, or null on cancel.
Future<EncryptOptions?> showEncryptDialog(
  BuildContext context, {
  int itemCount = 1,
  String? displayName,
}) {
  return showDialog<EncryptOptions>(
    context: context,
    builder: (context) => _EncryptDialog(itemCount: itemCount, displayName: displayName),
  );
}

/// Shows the decryption dialog and returns the entered password, or null on cancel.
Future<String?> showDecryptDialog(
  BuildContext context, {
  String? fileName,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _DecryptDialog(fileName: fileName),
  );
}

class _EncryptDialog extends StatefulWidget {
  const _EncryptDialog({required this.itemCount, this.displayName});

  final int itemCount;
  final String? displayName;

  @override
  State<_EncryptDialog> createState() => _EncryptDialogState();
}

class _EncryptDialogState extends State<_EncryptDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showPassword = false;
  bool _encryptName = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.displayName != null
        ? widget.displayName!
        : '${widget.itemCount} item${widget.itemCount == 1 ? '' : 's'}';

    return AlertDialog(
      title: const Text('Encrypt'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            autofocus: true,
            obscureText: !_showPassword,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Confirm password',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          _CheckboxRow(
            title: 'Show password',
            value: _showPassword,
            onChanged: (value) => setState(() => _showPassword = value),
          ),
          _CheckboxRow(
            title: 'Encrypt file name',
            value: _encryptName,
            onChanged: (value) => setState(() => _encryptName = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('OK'),
        ),
      ],
    );
  }

  void _submit() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Password is required');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    Navigator.of(context).pop(
      EncryptOptions(password: password, encryptName: _encryptName),
    );
  }
}

class _DecryptDialog extends StatefulWidget {
  const _DecryptDialog({this.fileName});

  final String? fileName;

  @override
  State<_DecryptDialog> createState() => _DecryptDialogState();
}

class _DecryptDialogState extends State<_DecryptDialog> {
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Decrypt'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.fileName != null) ...[
            Text(
              widget.fileName!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _passwordController,
            autofocus: true,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          _CheckboxRow(
            title: 'Show password',
            value: _showPassword,
            onChanged: (value) => setState(() => _showPassword = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('OK'),
        ),
      ],
    );
  }

  void _submit() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Password is required');
      return;
    }
    Navigator.of(context).pop(password);
  }
}

class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title),
            ),
          ],
        ),
      ),
    );
  }
}
