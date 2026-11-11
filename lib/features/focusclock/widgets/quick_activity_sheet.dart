import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class QuickActivityDraft {
  const QuickActivityDraft({
    required this.title,
    required this.durationMinutes,
  });

  final String title;
  final int durationMinutes;
}

Future<QuickActivityDraft?> showQuickActivitySheet(
  BuildContext context, {
  required String startLabel,
  required List<int> durationOptions,
  required int initialDuration,
}) {
  return showModalBottomSheet<QuickActivityDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickActivitySheet(
      startLabel: startLabel,
      durationOptions: durationOptions,
      initialDuration: initialDuration,
    ),
  );
}

class _QuickActivitySheet extends StatefulWidget {
  const _QuickActivitySheet({
    required this.startLabel,
    required this.durationOptions,
    required this.initialDuration,
  });

  final String startLabel;
  final List<int> durationOptions;
  final int initialDuration;

  @override
  State<_QuickActivitySheet> createState() => _QuickActivitySheetState();
}

class _QuickActivitySheetState extends State<_QuickActivitySheet> {
  late final TextEditingController _titleController;
  late int _duration;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _duration = widget.initialDuration;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _place() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(
      context,
    ).pop(QuickActivityDraft(title: title, durationMinutes: _duration));
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + keyboardInset),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppPalette.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppPalette.stroke),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What goes here?',
                  style: TextStyle(
                    color: AppPalette.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Starts at ${widget.startLabel}',
                  style: const TextStyle(
                    color: AppPalette.textDim,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  autofocus: true,
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _place(),
                  style: const TextStyle(color: AppPalette.text),
                  decoration: InputDecoration(
                    hintText: 'e.g. Study LKS',
                    labelText: 'Activity',
                    filled: true,
                    fillColor: AppPalette.bookpaperFieldBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppPalette.bookpaperBorder,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Duration',
                  style: TextStyle(
                    color: AppPalette.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: widget.durationOptions.map((minutes) {
                    final selected = _duration == minutes;
                    return ChoiceChip(
                      label: Text('${minutes}m'),
                      selected: selected,
                      onSelected: (_) => setState(() => _duration = minutes),
                      selectedColor: AppPalette.accent,
                      backgroundColor: AppPalette.bg,
                      labelStyle: TextStyle(
                        color: selected ? AppPalette.bg : AppPalette.text,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: selected ? AppPalette.accent : AppPalette.stroke,
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _titleController,
                  builder: (context, value, _) => SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: value.text.trim().isEmpty ? null : _place,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.accent,
                        foregroundColor: AppPalette.bg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Place on clock'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
