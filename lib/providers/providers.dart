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

/// The task currently being scheduled into the clock.
final schedulingTaskProvider = StateProvider<Task?>((_) => null);

/// Chat transcript — survives panel open/close so conversation continues.
/// "New chat" replaces it with an empty list.
final aiTranscriptProvider =
    StateProvider<List<ChatMessage>>((_) => <ChatMessage>[]);

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
