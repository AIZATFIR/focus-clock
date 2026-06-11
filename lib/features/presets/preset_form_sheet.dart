import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/preset.dart';
import '../../providers/providers.dart';
import '../../widgets/color_swatch_picker.dart';

Future<void> showPresetFormSheet(
  BuildContext context, {
  Preset? existing,
}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PresetForm(existing: existing),
    );

class _PresetForm extends ConsumerStatefulWidget {
  const _PresetForm({this.existing});
  final Preset? existing;
  @override
  ConsumerState<_PresetForm> createState() => _PresetFormState();
}

class _PresetFormState extends ConsumerState<_PresetForm> {
  late TextEditingController _nameCtrl;
  late int _color;
  String? _iconKey;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _color = widget.existing?.colorValue ?? presetColors.first;
    _iconKey = widget.existing?.iconKey;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + pad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'New Preset' : 'Edit Preset',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Icon', style: TextStyle(color: AppPalette.textDim)),
          const SizedBox(height: 8),
          _IconPicker(
            value: _iconKey,
            onChanged: (v) => setState(() => _iconKey = v),
          ),
          const SizedBox(height: 16),
          const Text('Color', style: TextStyle(color: AppPalette.textDim)),
          const SizedBox(height: 10),
          ColorSwatchPicker(
            value: _color,
            onChanged: (c) => setState(() => _color = c),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (widget.existing != null)
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text('Delete',
                      style: TextStyle(color: Colors.redAccent)),
                  onPressed: () async {
                    await ref
                        .read(presetRepoProvider)
                        .delete(widget.existing!.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final p = widget.existing ?? Preset();
    p.name = name;
    p.colorValue = _color;
    p.iconKey = _iconKey;
    p.createdAt = widget.existing?.createdAt ?? DateTime.now();
    await ref.read(presetRepoProvider).upsert(p);
    if (mounted) Navigator.pop(context);
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "No icon" option
        GestureDetector(
          onTap: () => onChanged(null),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(
                color: value == null ? AppPalette.accent : AppPalette.stroke,
                width: value == null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close, size: 16, color: AppPalette.textDim),
          ),
        ),
        ...presetIcons.map((icon) {
          final selected = value == icon;
          return GestureDetector(
            onTap: () => onChanged(icon),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? AppPalette.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                border: Border.all(
                  color: selected ? AppPalette.accent : AppPalette.stroke,
                  width: selected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
            ),
          );
        }),
      ],
    );
  }
}
