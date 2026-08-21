import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/time_math.dart';
import '../../../models/routine_blueprint.dart';
import '../widgets/blueprint_clock_preview.dart';
import 'apply_blueprint_dialog.dart';

class BlueprintDetailDialog extends StatelessWidget {
  final RoutineBlueprint blueprint;
  final VoidCallback onCustomize;

  const BlueprintDetailDialog({
    super.key,
    required this.blueprint,
    required this.onCustomize,
  });

  static Future<void> show(
    BuildContext context, {
    required RoutineBlueprint blueprint,
    required VoidCallback onCustomize,
  }) {
    return showDialog(
      context: context,
      builder: (_) => BlueprintDetailDialog(
        blueprint: blueprint,
        onCustomize: onCustomize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = blueprint;

    return Dialog(
      backgroundColor: const Color(0xFF14141E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      child: Container(
        width: 640,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAB308).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(b.iconKey, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              b.category,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'oleh ${b.author}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b.tagline,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Philosophy Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: Color(0xFFEAB308), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filosofi & Tujuan Rutinitas:',
                          style: TextStyle(
                            color: Color(0xFFEAB308),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          b.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Rangkaian Blok Waktu 24 Jam:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Scrollable Block List with Mini Clocks
            Expanded(
              child: ListView.separated(
                itemCount: b.blocks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final block = b.blocks[index];
                  final timeSpanStr =
                      '${formatMinute(block.startMinute, block.ampmHalf)} – ${formatMinute(block.endMinute, block.ampmHalf)}';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Color(block.colorValue).withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color(block.colorValue).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(block.iconKey,
                              style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    block.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    timeSpanStr,
                                    style: TextStyle(
                                      color: Color(block.colorValue),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (block.philosophy.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  block.philosophy,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCustomize();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Sesuaikan di Studio'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ApplyBlueprintDialog.show(context, b);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAB308),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text(
                    'Terapkan ke Focus Clock',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
