import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/routine_blueprint.dart';
import '../../providers/providers.dart';
import 'widgets/blueprint_clock_preview.dart';

class BlueprintEditorSheet extends ConsumerStatefulWidget {
  final RoutineBlueprint? initialBlueprint;

  const BlueprintEditorSheet({super.key, this.initialBlueprint});

  static Future<void> show(BuildContext context, {RoutineBlueprint? blueprint}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlueprintEditorSheet(initialBlueprint: blueprint),
    );
  }

  @override
  ConsumerState<BlueprintEditorSheet> createState() =>
      _BlueprintEditorSheetState();
}

class _BlueprintEditorSheetState extends ConsumerState<BlueprintEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _taglineController;
  late final TextEditingController _descController;
  late String _category;
  late String _iconKey;
  late List<BlueprintBlock> _blocks;

  final List<String> _categories = [
    'Spiritual & Focus',
    'High Performance',
    'Balance & Wellness',
    'Creative & Design',
    'Custom Routine',
  ];

  final List<String> _icons = ['🕌', '⚡', '🌿', '🎯', '💻', '🎨', '🚀', '🏃', '📚', '☕'];

  @override
  void initState() {
    super.initState();
    final b = widget.initialBlueprint;
    _nameController = TextEditingController(
        text: b != null ? (b.author == 'Official Dev' ? '${b.name} (Custom)' : b.name) : 'Rutinitas Harian Saya');
    _taglineController = TextEditingController(
        text: b?.tagline ?? 'Pola waktu harian yang sadar dan produktif.');
    _descController = TextEditingController(
        text: b?.description ?? 'Alasan dan filosofi di balik rutinitas ini.');
    _category = b?.category ?? 'Balance & Wellness';
    _iconKey = b?.iconKey ?? '⚡';
    _blocks = b != null ? List.from(b.blocks) : _defaultSeedBlocks();
  }

  List<BlueprintBlock> _defaultSeedBlocks() => [
        const BlueprintBlock(
          title: 'Deep Work Session',
          startMinute: 360, // 06:00 AM
          endMinute: 540,   // 09:00 AM
          ampmHalf: AmPmHalf.am,
          iconKey: '💻',
          colorValue: 0xFF3B82F6,
          philosophy: 'Fokus mendalam tanpa gangguan.',
          category: 'Deepwork',
        ),
        const BlueprintBlock(
          title: 'Midday Reset & Lunch',
          startMinute: 0,   // 12:00 PM
          endMinute: 90,    // 01:30 PM
          ampmHalf: AmPmHalf.pm,
          iconKey: '🥗',
          colorValue: 0xFFEAB308,
          philosophy: 'Makan bergizi dan istirahat sejenak.',
          category: 'Rest',
        ),
        const BlueprintBlock(
          title: 'Exercise & Health',
          startMinute: 300, // 05:00 PM
          endMinute: 420,   // 07:00 PM
          ampmHalf: AmPmHalf.pm,
          iconKey: '🏃',
          colorValue: 0xFF10B981,
          philosophy: 'Aktivitas fisik menjaga kebugaran.',
          category: 'Exercise',
        ),
      ];

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addBlock() {
    setState(() {
      _blocks.add(
        const BlueprintBlock(
          title: 'Aktivitas Baru',
          startMinute: 480, // 08:00 AM
          endMinute: 600,   // 10:00 AM
          ampmHalf: AmPmHalf.am,
          iconKey: '⚡',
          colorValue: 0xFF8B5CF6,
          philosophy: 'Tujuan blok ini.',
          category: 'General',
        ),
      );
    });
  }

  void _editBlock(int index) async {
    final block = _blocks[index];
    final updated = await _showEditBlockDialog(context, block);
    if (updated != null) {
      setState(() {
        _blocks[index] = updated;
      });
    }
  }

  void _deleteBlock(int index) {
    setState(() {
      _blocks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF13131F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.auto_stories_rounded,
                    color: Color(0xFFEAB308), size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Template Maker Studio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Form & Block List
                Expanded(
                  flex: 3,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Blueprint Name
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Nama Blueprint / Rutinitas',
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Tagline
                      TextField(
                        controller: _taglineController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Tagline Singkat',
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Philosophy / Description
                      TextField(
                        controller: _descController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Filosofi & Tujuan Rutinitas (Recipe to a Good Life)',
                          labelStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Category & Icon Selector
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _category,
                              dropdownColor: const Color(0xFF1E1E2E),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Kategori',
                                labelStyle: const TextStyle(color: Colors.white60),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.04),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _categories
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _category = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _iconKey,
                              dropdownColor: const Color(0xFF1E1E2E),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Ikon Utama',
                                labelStyle: const TextStyle(color: Colors.white60),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.04),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _icons
                                  .map((ic) => DropdownMenuItem(
                                      value: ic, child: Text('$ic  $ic')))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _iconKey = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Blocks Section Header
                      Row(
                        children: [
                          const Text(
                            'Blok Waktu Rutinitas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: _addBlock,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEAB308),
                              side: const BorderSide(color: Color(0xFFEAB308)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Tambah Blok'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Reorderable / Editable Blocks List
                      ...List.generate(_blocks.length, (index) {
                        final b = _blocks[index];
                        final timeStr =
                            '${formatMinute(b.startMinute, b.ampmHalf)} – ${formatMinute(b.endMinute, b.ampmHalf)}';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Color(b.colorValue).withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(b.colorValue).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(b.iconKey,
                                    style: const TextStyle(fontSize: 18)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: Color(b.colorValue),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _editBlock(index),
                                icon: const Icon(Icons.edit_outlined,
                                    color: Colors.white70, size: 18),
                                tooltip: 'Edit Blok',
                              ),
                              IconButton(
                                onPressed: () => _deleteBlock(index),
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent, size: 18),
                                tooltip: 'Hapus Blok',
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                // Right Panel: Live Dial Preview & Summary
                Container(
                  width: 280,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    border: const Border(
                      left: BorderSide(color: Colors.white10),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Live Dial Preview',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Realtime Mini Clock Preview
                      BlueprintClockPreview(
                        blocks: _blocks,
                        size: 160,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_blocks.length} Blok Waktu Terpasang',
                        style: const TextStyle(
                          color: Color(0xFFEAB308),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _saveBlueprint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEAB308),
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text(
                          'Simpan Blueprint',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<BlueprintBlock?> _showEditBlockDialog(
      BuildContext context, BlueprintBlock block) async {
    final titleCtrl = TextEditingController(text: block.title);
    final philCtrl = TextEditingController(text: block.philosophy);
    int start = block.startMinute;
    int end = block.endMinute;
    AmPmHalf half = block.ampmHalf;
    int color = block.colorValue;
    String icon = block.iconKey;

    return showDialog<BlueprintBlock>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Edit Blok Waktu', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nama Aktivitas',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: philCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Mengapa Blok Ini Ada (Filosofi)',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                ),
                const SizedBox(height: 16),
                // Half selector
                Row(
                  children: [
                    const Text('Bagian Hari:', style: TextStyle(color: Colors.white70)),
                    const Spacer(),
                    ChoiceChip(
                      label: const Text('AM (00-12)'),
                      selected: half == AmPmHalf.am,
                      onSelected: (s) =>
                          setDialogState(() => half = AmPmHalf.am),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('PM (12-24)'),
                      selected: half == AmPmHalf.pm,
                      onSelected: (s) =>
                          setDialogState(() => half = AmPmHalf.pm),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Time Sliders
                Row(
                  children: [
                    Text('Mulai: ${formatMinute(start, half)}',
                        style: const TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Slider(
                        value: (start / 15).round().toDouble(),
                        min: 0,
                        max: 48,
                        divisions: 48,
                        onChanged: (v) {
                          setDialogState(() {
                            start = (v * 15).toInt();
                            if (end <= start) end = (start + 60) % 720;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('Selesai: ${formatMinute(end, half)}',
                        style: const TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Slider(
                        value: (end / 15).round().toDouble(),
                        min: 0,
                        max: 48,
                        divisions: 48,
                        onChanged: (v) {
                          setDialogState(() => end = (v * 15).toInt());
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final result = block.copyWith(
                  title: titleCtrl.text.trim().isEmpty ? 'Aktivitas' : titleCtrl.text.trim(),
                  philosophy: philCtrl.text.trim(),
                  startMinute: start,
                  endMinute: end,
                  ampmHalf: half,
                  colorValue: color,
                  iconKey: icon,
                );
                Navigator.of(ctx).pop(result);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveBlueprint() {
    final name = _nameController.text.trim().isEmpty
        ? 'Rutinitas Kustom'
        : _nameController.text.trim();
    final tagline = _taglineController.text.trim();
    final description = _descController.text.trim();

    final isNew = widget.initialBlueprint == null ||
        widget.initialBlueprint!.author == 'Official Dev';

    final toSave = RoutineBlueprint(
      id: isNew ? DateTime.now().millisecondsSinceEpoch : widget.initialBlueprint!.id,
      name: name,
      tagline: tagline,
      description: description,
      author: 'Custom (User)',
      category: _category,
      iconKey: _iconKey,
      blocks: _blocks,
    );

    ref.read(blueprintRepoProvider).save(toSave);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        content: Text('✨ Blueprint "$name" berhasil disimpan!'),
      ),
    );
  }
}
