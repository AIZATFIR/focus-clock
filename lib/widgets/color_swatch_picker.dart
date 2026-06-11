import 'package:flutter/material.dart';

import '../core/theme.dart';

class ColorSwatchPicker extends StatelessWidget {
  const ColorSwatchPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: presetColors.map((c) {
          final selected = c == value;
          return GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppPalette.accent : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
          );
        }).toList(),
      );
}
