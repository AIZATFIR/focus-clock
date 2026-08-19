import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/features/flowchart/flowchart_canvas_view.dart';

void main() {
  group('Flowchart Model & Logic Tests', () {
    test('FlowchartNode initialization correctly assigns attributes', () {
      final node = FlowchartNode(
        id: 'test-1',
        title: 'Draft Flowchart Node',
        position: const Offset(100, 200),
        durationMinutes: 45,
        color: const Color(0xFFE6B800),
      );

      expect(node.id, 'test-1');
      expect(node.title, 'Draft Flowchart Node');
      expect(node.position, const Offset(100, 200));
      expect(node.durationMinutes, 45);
      expect(node.isCompleted, false);
    });

    test('FlowchartConnection links source and target node IDs', () {
      final connection = FlowchartConnection(
        id: 'conn-100',
        fromNodeId: 'node-A',
        toNodeId: 'node-B',
        label: 'Flow Step',
      );

      expect(connection.id, 'conn-100');
      expect(connection.fromNodeId, 'node-A');
      expect(connection.toNodeId, 'node-B');
      expect(connection.label, 'Flow Step');
    });
  });
}
