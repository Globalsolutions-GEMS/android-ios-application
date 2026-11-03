import 'package:flutter/material.dart';

const Color _primary = Color(0xFF6D4AFF);
const Color _dark = Color(0xFF172033);
const Color _grey = Color(0xFF64748B);
const Color _hint = Color(0xFF6B7280);
const Color _border = Color(0xFFB8C0D0);
const Color _red = Color(0xFFDC2626);

/// One option of [AppDropdown].
class AppDropdownItem<T> {
  const AppDropdownItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final T value;
  final String label;
  final bool enabled;
}

// Wraps the picked value so "dismissed" (null) differs from "cleared"
class _Choice<T> {
  const _Choice(this.value);

  final T? value;
}

/// Dropdown whose list opens right below the field (like the web).
/// First row is the hint (e.g. "Select Attendance Session"), it clears the value.
class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint = 'Select',
    this.value,
    this.required = true,
    this.errorText,
    this.enabled = true,
  });

  final String? label;
  final String hint;
  final T? value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?> onChanged; // null = hint row picked
  final bool required;
  final String? errorText;
  final bool enabled;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.items.where((i) => i.value == widget.value);
    return _FieldShell(
      label: widget.label,
      required: widget.required,
      text: selected.isEmpty ? null : selected.first.label,
      hint: widget.hint,
      icon: Icons.keyboard_arrow_down_rounded,
      errorText: widget.errorText,
      enabled: widget.enabled,
      highlighted: _open,
      onTap: _openMenu,
    );
  }

  Future<void> _openMenu(BuildContext fieldContext) async {
    // Place the list just below the field, with the same width
    final box = fieldContext.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(fieldContext).context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final top = origin.dy + box.size.height + 4;
    final available = overlay.size.height - top - 12;
    final maxHeight = available < 160
        ? 160.0
        : (available > 320 ? 320.0 : available);

    final position = RelativeRect.fromLTRB(
      origin.dx,
      top,
      overlay.size.width - origin.dx - box.size.width,
      overlay.size.height - top,
    );

    setState(() => _open = true);

    final picked = await showMenu<_Choice<T>>(
      context: fieldContext,
      position: position,
      constraints: BoxConstraints(
        minWidth: box.size.width,
        maxWidth: box.size.width,
        maxHeight: maxHeight,
      ),
      color: Colors.white,
      elevation: 6,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _border),
      ),
      items: [
        // Hint row: clears the selection
        PopupMenuItem<_Choice<T>>(
          value: _Choice<T>(null),
          padding: EdgeInsets.zero,
          child: _MenuRow(
            label: widget.hint,
            selected: widget.value == null,
            enabled: true,
            isHint: true,
          ),
        ),
        for (final item in widget.items)
          PopupMenuItem<_Choice<T>>(
            value: _Choice<T>(item.value),
            enabled: item.enabled,
            padding: EdgeInsets.zero,
            child: _MenuRow(
              label: item.label,
              selected: item.value == widget.value,
              enabled: item.enabled,
            ),
          ),
      ],
    );

    if (mounted) setState(() => _open = false);
    if (picked != null) widget.onChanged(picked.value);
  }
}

// One row of the dropdown list
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.selected,
    required this.enabled,
    this.isHint = false,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final bool isHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: selected ? _primary.withOpacity(0.08) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected && !isHint
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isHint
                    ? _hint
                    : (!enabled ? _hint : (selected ? _primary : _dark)),
              ),
            ),
          ),
          if (selected && !isHint)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check_rounded, size: 18, color: _primary),
            ),
        ],
      ),
    );
  }
}

/// Read-only field that runs [onTap] (date picker etc.).
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.onTap,
    this.label,
    this.hint = 'Select',
    this.text,
    this.icon = Icons.calendar_today_outlined,
    this.required = true,
    this.errorText,
  });

  final String? label;
  final String hint;
  final String? text;
  final IconData icon;
  final VoidCallback onTap;
  final bool required;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      required: required,
      text: text,
      hint: hint,
      icon: icon,
      errorText: errorText,
      onTap: (_) => onTap(),
    );
  }
}

// Shared look: label, bordered box, error text
class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.label,
    required this.required,
    required this.text,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.errorText,
    this.enabled = true,
    this.highlighted = false,
  });

  final String? label;
  final bool required;
  final String? text;
  final String hint;
  final IconData icon;
  final ValueChanged<BuildContext> onTap; // gets the field's own context
  final String? errorText;
  final bool enabled;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final borderColor = hasError ? _red : (highlighted ? _primary : _border);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                ),
                children: [
                  if (required)
                    const TextSpan(text: ' *', style: TextStyle(color: _red)),
                ],
              ),
            ),
          ),
        // Builder gives the context of the box only (used to place the list)
        Builder(
          builder: (fieldContext) => Material(
            color: enabled ? Colors.white : const Color(0xFFF1F5F9),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: borderColor,
                width: highlighted ? 2 : 1.2,
              ),
            ),
            child: InkWell(
              onTap: enabled ? () => onTap(fieldContext) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text ?? hint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: text == null
                              ? FontWeight.w400
                              : FontWeight.w500,
                          color: text == null ? _hint : _dark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, size: 22, color: enabled ? _primary : _grey),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(fontSize: 12, color: _red),
            ),
          ),
      ],
    );
  }
}