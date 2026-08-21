import 'package:flutter/material.dart';
import '../../../models/routine_blueprint.dart';
import '../dialogs/apply_blueprint_dialog.dart';
import '../dialogs/blueprint_detail_dialog.dart';
import 'blueprint_clock_preview.dart';

class BlueprintCard extends StatelessWidget {
  final RoutineBlueprint blueprint;
  final VoidCallback onCustomize;

  const BlueprintCard({
    super.key,
    required this.blueprint,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    final b = blueprint;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => BlueprintDetailDialog.show(
            context,
            blueprint: b,
            onCustomize: onCustomize,
          ),
          borderRadius: BorderRadius.circular(20),
          hoverColor: Colors.white.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category Pill & Author
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        b.category,
                        style: const TextStyle(
                          color: Color(0xFFEAB308),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        b.author,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${b.blocks.length} Blok',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Middle Row: Title + Clock Preview
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(b.iconKey, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  b.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            b.tagline,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Mini Visual Dial Preview
                    BlueprintClockPreview(
                      blocks: b.blocks,
                      size: 78,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 14),
                // Bottom Action Buttons
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => BlueprintDetailDialog.show(
                        context,
                        blueprint: b,
                        onCustomize: onCustomize,
                      ),
                      icon: const Icon(Icons.menu_book_rounded, size: 16, color: Colors.white70),
                      label: const Text(
                        'Baca Panduan',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: onCustomize,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.15)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 14),
                      label: const Text('Edit', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => ApplyBlueprintDialog.show(context, b),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEAB308),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 16),
                      label: const Text(
                        'Terapkan',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
