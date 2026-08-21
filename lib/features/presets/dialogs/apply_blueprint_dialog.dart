import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/routine_blueprint.dart';
import '../../../providers/providers.dart';

class ApplyBlueprintDialog extends ConsumerStatefulWidget {
  final RoutineBlueprint blueprint;

  const ApplyBlueprintDialog({super.key, required this.blueprint});

  static Future<void> show(BuildContext context, RoutineBlueprint blueprint) {
    return showDialog(
      context: context,
      builder: (_) => ApplyBlueprintDialog(blueprint: blueprint),
    );
  }

  @override
  ConsumerState<ApplyBlueprintDialog> createState() =>
      _ApplyBlueprintDialogState();
}

class _ApplyBlueprintDialogState extends ConsumerState<ApplyBlueprintDialog> {
  bool _isDailyRecurring = true;
  DateTime _selectedDate = DateTime.now();
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.blueprint;

    return Dialog(
      backgroundColor: const Color(0xFF181824),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAB308).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(b.iconKey, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terapkan ke Focus Clock',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        b.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Text(
                'Blueprint ini akan memetakan ${b.blocks.length} blok aktivitas sadar ke dalam dial jam Focus Clock.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mode Penerapan Jadwal:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            // Daily Recurring Option
            InkWell(
              onTap: () => setState(() => _isDailyRecurring = true),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _isDailyRecurring
                      ? const Color(0xFFEAB308).withOpacity(0.12)
                      : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDailyRecurring
                        ? const Color(0xFFEAB308).withOpacity(0.5)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isDailyRecurring
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: _isDailyRecurring
                          ? const Color(0xFFEAB308)
                          : Colors.white38,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rutinitas Harian Berulang (Setiap Hari)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Otomatis terpasang di jam setiap hari sebagai pola hidup tetap.',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Specific Date Option
            InkWell(
              onTap: () => setState(() => _isDailyRecurring = false),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: !_isDailyRecurring
                      ? const Color(0xFFEAB308).withOpacity(0.12)
                      : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !_isDailyRecurring
                        ? const Color(0xFFEAB308).withOpacity(0.5)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      !_isDailyRecurring
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: !_isDailyRecurring
                          ? const Color(0xFFEAB308)
                          : Colors.white38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hanya untuk Tanggal Tertentu: ${DateFormat('d MMMM yyyy').format(_selectedDate)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'Terapkan sebagai jadwal mandiri tanpa perulangan otomatis.',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (!_isDailyRecurring)
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: const Text('Ganti Tanggal'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isApplying ? null : _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAB308),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isApplying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    _isApplying ? 'Menerapkan...' : 'Terapkan ke Jam Sekarang',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply() async {
    setState(() => _isApplying = true);
    try {
      final applier = ref.read(blueprintApplierServiceProvider);
      final count = await applier.applyBlueprint(
        blueprint: widget.blueprint,
        targetDate: _selectedDate,
        isDailyRecurring: _isDailyRecurring,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(
              '🎉 Berhasil menerapkan $count blok dari "${widget.blueprint.name}" ke jam!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Gagal menerapkan blueprint: $e'),
          ),
        );
      }
    }
  }
}
