import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';

class FlowchartNode {
  FlowchartNode({
    required this.id,
    required this.title,
    required this.position,
    this.durationMinutes = 30,
    this.color = const Color(0xFFE6B800),
    this.icon = '🎯',
    this.isCompleted = false,
  });

  final String id;
  String title;
  Offset position;
  int durationMinutes;
  Color color;
  String icon;
  bool isCompleted;
}

class FlowchartConnection {
  FlowchartConnection({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.label,
  });

  final String id;
  final String fromNodeId;
  final String toNodeId;
  final String? label;
}

final flowchartNodesProvider = StateProvider<List<FlowchartNode>>((ref) {
  return [
    FlowchartNode(
      id: 'node-1',
      title: '🎯 Deep Work Sesi 1',
      position: const Offset(150, 200),
      durationMinutes: 45,
      color: const Color(0xFFE6B800),
    ),
    FlowchartNode(
      id: 'node-2',
      title: '☕ Istirahat & Kopi',
      position: const Offset(420, 200),
      durationMinutes: 15,
      color: const Color(0xFF4EAA86),
    ),
    FlowchartNode(
      id: 'node-3',
      title: '💻 Review & Refactor Kode',
      position: const Offset(420, 360),
      durationMinutes: 60,
      color: const Color(0xFF8C9EFF),
    ),
  ];
});

final flowchartConnectionsProvider = StateProvider<List<FlowchartConnection>>((ref) {
  return [
    FlowchartConnection(
      id: 'conn-1',
      fromNodeId: 'node-1',
      toNodeId: 'node-2',
      label: 'Lanjut',
    ),
    FlowchartConnection(
      id: 'conn-2',
      fromNodeId: 'node-2',
      toNodeId: 'node-3',
      label: 'Fokus 2',
    ),
  ];
});

class FlowchartCanvasView extends ConsumerStatefulWidget {
  const FlowchartCanvasView({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  ConsumerState<FlowchartCanvasView> createState() => _FlowchartCanvasViewState();
}

class _FlowchartCanvasViewState extends ConsumerState<FlowchartCanvasView> {
  final TransformationController _transformationController = TransformationController();
  String? _selectedNodeId;
  String? _connectingFromNodeId;
  Offset? _dragConnectionCurrentPos;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _addNodeAtOffset(Offset sceneOffset) {
    HapticFeedback.mediumImpact();
    final newId = 'node-${DateTime.now().millisecondsSinceEpoch}';
    final newNode = FlowchartNode(
      id: newId,
      title: 'Nodal Fokus ${ref.read(flowchartNodesProvider).length + 1}',
      position: sceneOffset,
      durationMinutes: 30,
      color: AppPalette.accent,
    );

    ref.read(flowchartNodesProvider.notifier).update((list) => [...list, newNode]);
    setState(() => _selectedNodeId = newId);
  }

  void _deleteNode(String nodeId) {
    HapticFeedback.mediumImpact();
    ref.read(flowchartNodesProvider.notifier).update((list) => list.where((n) => n.id != nodeId).toList());
    ref.read(flowchartConnectionsProvider.notifier).update(
          (list) => list.where((c) => c.fromNodeId != nodeId && c.toNodeId != nodeId).toList(),
        );
    if (_selectedNodeId == nodeId) {
      setState(() => _selectedNodeId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(flowchartNodesProvider);
    final connections = ref.watch(flowchartConnectionsProvider);

    return Scaffold(
      backgroundColor: AppPalette.blackBg,
      body: Stack(
        children: [
          // Infinite Canvas Interactive Area
          GestureDetector(
            onDoubleTapDown: (details) {
              final sceneOffset = _transformationController.toScene(details.localPosition);
              _addNodeAtOffset(sceneOffset);
            },
            onTap: () {
              if (_selectedNodeId != null) {
                setState(() {
                  _selectedNodeId = null;
                  _connectingFromNodeId = null;
                });
              }
            },
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.2,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(2000),
              child: SizedBox(
                width: 4000,
                height: 4000,
                child: CustomPaint(
                  painter: _FlowchartCanvasPainter(
                    nodes: nodes,
                    connections: connections,
                    selectedNodeId: _selectedNodeId,
                    connectingFromNodeId: _connectingFromNodeId,
                    dragConnectionCurrentPos: _dragConnectionCurrentPos,
                  ),
                  child: Stack(
                    children: [
                      // Node Widgets on Canvas
                      for (final node in nodes)
                        Positioned(
                          left: node.position.dx,
                          top: node.position.dy,
                          child: _NodeWidget(
                            node: node,
                            isSelected: _selectedNodeId == node.id,
                            isConnectingFrom: _connectingFromNodeId == node.id,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              if (_connectingFromNodeId != null && _connectingFromNodeId != node.id) {
                                // Create connection
                                final newConn = FlowchartConnection(
                                  id: 'conn-${DateTime.now().millisecondsSinceEpoch}',
                                  fromNodeId: _connectingFromNodeId!,
                                  toNodeId: node.id,
                                );
                                ref
                                    .read(flowchartConnectionsProvider.notifier)
                                    .update((list) => [...list, newConn]);
                                setState(() {
                                  _connectingFromNodeId = null;
                                  _selectedNodeId = node.id;
                                });
                              } else {
                                setState(() => _selectedNodeId = node.id);
                              }
                            },
                            onPanUpdate: (delta) {
                              setState(() {
                                node.position += delta;
                              });
                            },
                            onStartConnect: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _connectingFromNodeId = node.id;
                              });
                            },
                            onDelete: () => _deleteNode(node.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Apple-style Minimalist Ambient Top Glass Bar (No Floating Action Buttons)
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Minimal Glass Title Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppPalette.card.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppPalette.stroke.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_tree_rounded, size: 16, color: AppPalette.accent),
                      const SizedBox(width: 8),
                      Text(
                        'FLOWCHART CANVAS (${nodes.length} NODES)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppPalette.text,
                        ),
                      ),
                    ],
                  ),
                ),

                // Close Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (widget.onClose != null) {
                      widget.onClose!();
                    } else if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppPalette.card.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppPalette.stroke.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppPalette.text),
                  ),
                ),
              ],
            ),
          ),

          // Minimal Gesture Hint Pill (Fades naturally)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppPalette.card.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPalette.stroke.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  '💡 Double-tap canvas untuk tambah node • Drag node untuk geser • Tap titik kanan untuk hubungkan',
                  style: TextStyle(fontSize: 11, color: AppPalette.textDim, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeWidget extends StatelessWidget {
  const _NodeWidget({
    required this.node,
    required this.isSelected,
    required this.isConnectingFrom,
    required this.onTap,
    required this.onPanUpdate,
    required this.onStartConnect,
    required this.onDelete,
  });

  final FlowchartNode node;
  final bool isSelected;
  final bool isConnectingFrom;
  final VoidCallback onTap;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onStartConnect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) => onPanUpdate(details.delta),
      child: AnimatedContainer(
        duration: GeminiMotion.fast,
        curve: GeminiMotion.springCurve,
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppPalette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppPalette.accent
                : isConnectingFrom
                    ? Colors.greenAccent
                    : AppPalette.stroke,
            width: isSelected || isConnectingFrom ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppPalette.accent.withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: 2,
              )
            else
              const BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(node.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    node.title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.close, size: 14, color: AppPalette.danger),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: node.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${node.durationMinutes} m',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: node.color),
                  ),
                ),

                // Connection Handle Dot
                GestureDetector(
                  onTap: onStartConnect,
                  child: Tooltip(
                    message: 'Hubungkan Node',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isConnectingFrom ? Colors.greenAccent : AppPalette.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.black),
                    ),
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

class _FlowchartCanvasPainter extends CustomPainter {
  _FlowchartCanvasPainter({
    required this.nodes,
    required this.connections,
    this.selectedNodeId,
    this.connectingFromNodeId,
    this.dragConnectionCurrentPos,
  });

  final List<FlowchartNode> nodes;
  final List<FlowchartConnection> connections;
  final String? selectedNodeId;
  final String? connectingFromNodeId;
  final Offset? dragConnectionCurrentPos;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppPalette.stroke.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    // Draw Grid Lines
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw Connections
    final linePaint = Paint()
      ..color = AppPalette.accent.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final nodeMap = {for (final n in nodes) n.id: n};

    for (final conn in connections) {
      final from = nodeMap[conn.fromNodeId];
      final to = nodeMap[conn.toNodeId];
      if (from != null && to != null) {
        final start = from.position + const Offset(180, 30);
        final end = to.position + const Offset(0, 30);

        final path = Path();
        path.moveTo(start.dx, start.dy);
        final controlX = (start.dx + end.dx) / 2;
        path.cubicTo(controlX, start.dy, controlX, end.dy, end.dx, end.dy);

        canvas.drawPath(path, linePaint);

        // Arrow head
        final arrowPaint = Paint()
          ..color = AppPalette.accent
          ..style = PaintingStyle.fill;
        canvas.drawCircle(end, 4, arrowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlowchartCanvasPainter oldDelegate) => true;
}
