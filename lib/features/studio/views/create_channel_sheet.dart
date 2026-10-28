import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';

/// Bottom sheet that creates a channel. Resolves to true when one was created.
Future<bool?> showCreateChannelSheet(BuildContext context, {String? reason}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => CreateChannelSheet(reason: reason),
  );
}

class CreateChannelSheet extends StatefulWidget {
  const CreateChannelSheet({super.key, this.reason});

  /// Why the sheet opened, e.g. "You need a channel before you can upload".
  final String? reason;

  @override
  State<CreateChannelSheet> createState() => _CreateChannelSheetState();
}

class _CreateChannelSheetState extends State<CreateChannelSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await context.read<AuthViewModel>().createChannel(_name.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + keyboard),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create your channel', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            widget.reason ??
                'A channel is where your videos live. You can create more than one with the same account.',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: AppTextField(
              controller: _name,
              label: 'Channel name',
              hint: 'For example: Code Academy',
              icon: Icons.live_tv_rounded,
              textInputAction: TextInputAction.done,
              validator: Validators.channelName,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          AppButton(label: 'Create channel', isLoading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
