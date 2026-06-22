import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../core/time_math.dart';
import '../data/repositories/activity_repository.dart';
import '../data/repositories/preset_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/task_repository.dart';
import '../models/activity.dart';
import '../models/app_settings.dart';
import '../models/preset.dart';
import '../models/task.dart';
import '../services/ai_service.dart';
import '../services/gcal_service.dart';
import '../services/notification_service.dart';

/// Overridden in main().
final isarProvider = Provider<Isar>((_) => throw UnimplementedError());
final notificationServiceProvider =
    Provider<NotificationService>((_) => throw UnimplementedError());

final presetRepoProvider = Provider<PresetRepository>(
  (ref) => PresetRepository(ref.watch(isarProvider)),
);

final activityRepoProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(
    ref.watch(isarProvider),
    ref.watch(notificationServiceProvider),
  ),
);

final taskRepoProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(isarProvider)),
);

final settingsRepoProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(isarProvider)),
);

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepoProvider).watch(),
);

final presetsProvider = StreamProvider<List<Preset>>(
  (ref) => ref.watch(presetRepoProvider).watchAll(),
);

/// Current date being viewed (default today).
final currentDateProvider =
    StateProvider<DateTime>((_) => dateOnly(DateTime.now()));

/// Current AM/PM half being viewed in FocusClock.
final ampmHalfProvider =
    StateProvider<AmPmHalf>((_) => halfOfNow());

/// Realtime clock tick.
final currentTimeProvider = StreamProvider<DateTime>(
  (_) => Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  ),
);

/// Activities filtered by date + half (used by FocusClock).
final activitiesByHalfProvider = StreamProvider<List<Activity>>((ref) {
  final date = ref.watch(currentDateProvider);
  final half = ref.watch(ampmHalfProvider);
  return ref.watch(activityRepoProvider).watchByDateAndHalf(date, half);
});

/// Activities for entire day (used by Agenda tab).
final activitiesByDateProvider = StreamProvider<List<Activity>>((ref) {
  final date = ref.watch(currentDateProvider);
  return ref.watch(activityRepoProvider).watchByDate(date);
});

/// Bottom-nav selected index.
final tabIndexProvider = StateProvider<int>((_) => 1);

/// Activities for current week (Mon–Sun), used by Weekly Evaluator.
final weekActivitiesProvider = StreamProvider<List<Activity>>((ref) {
  return ref.watch(activityRepoProvider).watchWeek(DateTime.now());
});

/// Google Calendar service singleton.
final gcalServiceProvider = Provider<GCalService>((_) => GCalService());

/// Whether the user is currently signed into GCal (updated after sign-in/out).
final gcalSignedInProvider = StateProvider<bool>((_) => false);

/// Tasks for Eisenhower Matrix.
final eisenhowerTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepoProvider).watchAll();
});

/// Tasks scheduled for the currently selected date and half.
final tasksByHalfProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(eisenhowerTasksProvider).valueOrNull ?? const [];
  final date = ref.watch(currentDateProvider);
  final half = ref.watch(ampmHalfProvider);
  final activities = ref.watch(activitiesByHalfProvider).valueOrNull ?? const [];
  final activityIds = activities.map((a) => a.id).toSet();
  
  return tasks.where((t) {
    if (t.startMinute == null || t.endMinute == null) return false;
    if (t.activityId != null) {
      return activityIds.contains(t.activityId);
    }
    return t.date != null && 
           t.date!.year == date.year &&
           t.date!.month == date.month &&
           t.date!.day == date.day &&
           t.ampmHalf == half;
  }).toList();
});

/// Unscheduled tasks (Inbox) that don't have start/end minutes.
final unscheduledTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(eisenhowerTasksProvider).valueOrNull ?? const [];
  return tasks.where((t) => t.startMinute == null || t.endMinute == null).toList();
});

/// Tasks assigned to a specific activity.
final tasksForActivityProvider = StreamProvider.family<List<Task>, int>((ref, activityId) {
  return ref.watch(taskRepoProvider).watchByActivity(activityId);
});

/// The task currently being scheduled into the clock.
final schedulingTaskProvider = StateProvider<Task?>((_) => null);

/// Chat transcript — survives panel open/close so conversation continues.
/// "New chat" replaces it with an empty list.
final aiTranscriptProvider =
    StateProvider<List<ChatMessage>>((_) => <ChatMessage>[]);

// ── Planning Mode State ──────────────────────────────────────────────────

/// Tracks whether the UI is in Planning Mode (Fullscreen Clock)
final planningModeProvider = StateProvider<bool>((ref) => false);

/// Tracks the specific date being planned. Defaults to today.
final planningDateProvider = StateProvider<DateTime>((ref) => dateOnly(DateTime.now()));

/// Tracks whether the clock is in Precision Mode (1-minute snapping)
final precisionModeProvider = StateProvider<bool>((ref) => false);

/// Tracks whether the clock is in Instant Mode (double click fill)
final isInstantModeProvider = StateProvider<bool>((ref) => false);

/// Tracks whether the user is actively dragging the clock hand or a segment
final isClockDraggingProvider = StateProvider<bool>((ref) => false);

/// Tracks the selected duration interval for Instant Mode (default 60 minutes)
final instantIntervalProvider = StateProvider<int>((ref) => 60);

/// Tasks scheduled for the currently selected date (entire 24h day).
final tasksByDateProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(eisenhowerTasksProvider).valueOrNull ?? const [];
  final date = ref.watch(currentDateProvider);
  final activities = ref.watch(activitiesByDateProvider).valueOrNull ?? const [];
  final activityIds = activities.map((a) => a.id).toSet();
  
  return tasks.where((t) {
    if (t.startMinute == null || t.endMinute == null) return false;
    if (t.activityId != null) {
      return activityIds.contains(t.activityId);
    }
    return t.date != null && 
           t.date!.year == date.year &&
           t.date!.month == date.month &&
           t.date!.day == date.day;
  }).toList();
});

/// AI service — lazily init on first use.
/// AI service — recreated when settings change.
final aiServiceProvider = Provider<AiService>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  return AiService(
    baseUrl: settings?.aiBaseUrl ?? 'https://openrouter.ai/api/v1',
    apiKey: settings?.aiApiKey ?? '',
    model: settings?.aiModel ?? 'google/gemini-2.0-flash-exp:free',
    activityRepo: ref.watch(activityRepoProvider),
    presetRepo: ref.watch(presetRepoProvider),
  );
});
