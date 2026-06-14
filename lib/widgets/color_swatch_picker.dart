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
        spacing: 8,
        runSpacing: 8,
        children: presetColors.map((c) {
          final selected = c == value;
          return GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: selected ? 2.5 : 0,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Color(c).withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            ),
          );
        }).toList(),
      );
}
