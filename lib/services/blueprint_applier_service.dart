import '../core/time_math.dart';
import '../data/repositories/activity_repository.dart';
import '../models/activity.dart';
import '../models/routine_blueprint.dart';

class BlueprintApplierService {
  final ActivityRepository activityRepo;

  BlueprintApplierService(this.activityRepo);

  Future<int> applyBlueprint({
    required RoutineBlueprint blueprint,
    required DateTime targetDate,
    required bool isDailyRecurring,
  }) async {
    final d = dateOnly(targetDate);
    final now = DateTime.now();
    int count = 0;

    for (final block in blueprint.blocks) {
      final activity = Activity()
        ..title = block.title
        ..startMinute = block.startMinute
        ..endMinute = block.endMinute
        ..ampmHalf = block.ampmHalf
        ..date = d
        ..description = block.philosophy
        ..colorValue = block.colorValue
        ..iconKey = block.iconKey
        ..recurrence = isDailyRecurring ? 'daily' : 'none'
        ..createdAt = now
        ..updatedAt = now;

      await activityRepo.upsert(activity);
      count++;
    }

    return count;
  }
}
