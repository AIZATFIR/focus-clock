import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/routine_blueprint.dart';

class BlueprintRepository {
  final List<RoutineBlueprint> _blueprints = [];
  final _controller = StreamController<List<RoutineBlueprint>>.broadcast();

  BlueprintRepository() {
    _blueprints.addAll([
      RoutineBlueprint.muslimFivePillars(),
      RoutineBlueprint.balancedHighPerformer(),
    ]);
  }

  Stream<List<RoutineBlueprint>> watchAll() {
    // Send immediate snapshot
    scheduleMicrotask(() => _controller.add(List.unmodifiable(_blueprints)));
    return _controller.stream;
  }

  List<RoutineBlueprint> getAll() => List.unmodifiable(_blueprints);

  List<RoutineBlueprint> getOfficial() =>
      _blueprints.where((b) => b.author == 'Official Dev').toList();

  List<RoutineBlueprint> getCustom() =>
      _blueprints.where((b) => b.author != 'Official Dev').toList();

  void save(RoutineBlueprint blueprint) {
    final idx = _blueprints.indexWhere((b) => b.id == blueprint.id);
    if (idx >= 0) {
      _blueprints[idx] = blueprint;
    } else {
      if (blueprint.id == 0) {
        blueprint.id = DateTime.now().millisecondsSinceEpoch;
      }
      _blueprints.add(blueprint);
    }
    _controller.add(List.unmodifiable(_blueprints));
  }

  void delete(int id) {
    _blueprints.removeWhere((b) => b.id == id && b.author != 'Official Dev');
    _controller.add(List.unmodifiable(_blueprints));
  }

  void dispose() {
    _controller.close();
  }
}
