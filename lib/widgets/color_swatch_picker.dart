import 'package:flutter/material.dart';

import '../core/theme.dart';

class ColorSwatchPicker extends StatefulWidget {
  const ColorSwatchPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<ColorSwatchPicker> createState() => _ColorSwatchPickerState();
}

class _ColorSwatchPickerState extends State<ColorSwatchPicker> {
  int _activeCategory = 0; // 0: Pastel Book, 1: Classic

  @override
  Widget build(BuildContext context) {
    final colors = _activeCategory == 0 ? pastelBookColors : presetColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _tabButton(0, '📖 Pastel Book (Ramah Mata)'),
            const SizedBox(width: 8),
            _tabButton(1, '✨ Classic Vibrant'),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((c) {
            final selected = c == widget.value;
            return GestureDetector(
              onTap: () => widget.onChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.white24,
                    width: selected ? 2.5 : 1.0,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Color(c).withValues(alpha: 0.35),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: selected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _tabButton(int index, String label) {
    final active = _activeCategory == index;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppPalette.accent.withValues(alpha: 0.15) : AppPalette.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppPalette.accent : AppPalette.stroke,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? AppPalette.accent : AppPalette.textDim,
          ),
        ),
      ),
    );
  }
}
