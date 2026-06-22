import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
import '../../providers/providers.dart';

Future<void> showTaskDetailSheet(BuildContext context, Task task) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _TaskDetailSheet(task: task),
  );
}

class _TaskDetailSheet extends ConsumerStatefulWidget {
  const _TaskDetailSheet({required this.task});
  final Task task;

  @override
  ConsumerState<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<_TaskDetailSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  final _subtaskCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subtaskCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    widget.task.title = _titleCtrl.text.trim().isEmpty ? 'Untitled Task' : _titleCtrl.text.trim();
    widget.task.description = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
    await ref.read(taskRepoProvider).update(widget.task);
  }

  Future<void> _addSubtask() async {
    final text = _subtaskCtrl.text.trim();
    if (text.isEmpty) return;
    final list = widget.task.subtaskList;
    list.add(SubTask(title: text));
    widget.task.subtaskList = list;
    await ref.read(taskRepoProvider).update(widget.task);
    _subtaskCtrl.clear();
    setState(() {});
  }

  Future<void> _toggleSubtask(int index, bool? val) async {
    if (val == null) return;
    final list = widget.task.subtaskList;
    list[index].isCompleted = val;
    widget.task.subtaskList = list;
    await ref.read(taskRepoProvider).update(widget.task);
    setState(() {});
  }

  Future<void> _deleteSubtask(int index) async {
    final list = widget.task.subtaskList;
    list.removeAt(index);
    widget.task.subtaskList = list;
    await ref.read(taskRepoProvider).update(widget.task);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final list = widget.task.subtaskList;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPalette.stroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Header Title
            const Text(
              'Edit Task',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppPalette.accent),
            ),
            const SizedBox(height: 16),

            // Title Input
            TextField(
              controller: _titleCtrl,
              onChanged: (_) => _saveChanges(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: const TextStyle(color: AppPalette.textDim),
                filled: true,
                fillColor: AppPalette.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Description Input
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              onChanged: (_) => _saveChanges(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: const TextStyle(color: AppPalette.textDim),
                filled: true,
                fillColor: AppPalette.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // Subtasks Header
            Row(
              children: [
                const Icon(Icons.playlist_add_check_rounded, size: 20, color: AppPalette.accent),
                const SizedBox(width: 8),
                Text(
                  'Subtasks (${list.where((s) => s.isCompleted).length}/${list.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Divider(height: 20, color: AppPalette.stroke),

            // Subtasks List
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No subtasks yet. Add one below!',
                  style: TextStyle(color: AppPalette.textDim, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final sub = list[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: sub.isCompleted,
                          activeColor: AppPalette.accent,
                          checkColor: Colors.black,
                          onChanged: (val) => _toggleSubtask(index, val),
                        ),
                        Expanded(
                          child: Text(
                            sub.title,
                            style: TextStyle(
                              fontSize: 14,
                              decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                              color: sub.isCompleted ? AppPalette.textDim : AppPalette.text,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppPalette.textDim),
                          onPressed: () => _deleteSubtask(index),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 12),

            // Add Subtask Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskCtrl,
                    onSubmitted: (_) => _addSubtask(),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add a subtask...',
                      hintStyle: const TextStyle(color: AppPalette.textDim),
                      filled: true,
                      fillColor: AppPalette.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppPalette.accent),
                  onPressed: _addSubtask,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(taskRepoProvider).delete(widget.task.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppPalette.danger, size: 20),
                  label: const Text('Delete Task', style: TextStyle(color: AppPalette.danger)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
