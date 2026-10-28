import 'package:flutter/material.dart';

/// Field that looks like a text field and opens a list when tapped.
class ChoiceField extends StatelessWidget {
  const ChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final String? value;
  final String hint;
  final IconData icon;
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(label, style: theme.textTheme.labelLarge),
        ),
        Material(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: errorText == null ? null : Border.all(color: scheme.error, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value ?? hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: value == null
                            ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  if (onTap != null) Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(errorText!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.error)),
          ),
      ],
    );
  }
}

/// Bottom sheet with a list of (id, label) options. Returns the chosen id.
Future<String?> pickOne(
  BuildContext context, {
  required String title,
  required List<(String, String)> options,
  required String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(title, style: theme.textTheme.headlineSmall),
              ),
              for (final option in options)
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  title: Text(option.$2),
                  trailing: option.$1 == selected
                      ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option.$1),
                ),
            ],
          ),
        ),
      );
    },
  );
}
