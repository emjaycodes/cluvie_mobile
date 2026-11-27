import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/notifications/data/notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notification settings (`/notifications/settings`): which push
/// notifications to get, and quiet hours (`/notifications/preferences`).
/// Each change saves at once; a refused save puts the switch back.
///
/// Gold budget: none.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _save(BuildContext context, WidgetRef ref, NotificationPrefs next, Map<String, Object?> body) async {
    try {
      await ref.read(notificationPrefsProvider.notifier).save(next, body);
    } catch (_) {
      if (context.mounted) {
        ClSnackbar.show(context, message: "Couldn't save that. Try again.", type: ClSnackbarType.error);
      }
    }
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref, NotificationPrefs p, {required bool start}) async {
    final current = start ? p.quietStart : p.quietEnd;
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      helpText: start ? 'Quiet from' : 'Quiet until',
    );
    if (picked == null || !context.mounted) return;
    final hhmm = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final next = NotificationPrefs(
      polls: p.polls,
      discussions: p.discussions,
      parties: p.parties,
      quietEnabled: p.quietEnabled,
      quietStart: start ? hhmm : p.quietStart,
      quietEnd: start ? p.quietEnd : hhmm,
    );
    await _save(context, ref, next, {
      'quietHours': {start ? 'start' : 'end': hhmm},
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: const ClAppBar(title: 'Notification settings', frosted: true, fallbackRoute: '/notifications'),
      body: prefs.when(
        skipLoadingOnRefresh: true,
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.gutter),
          child: Column(children: [ClSkeleton(height: 200), SizedBox(height: AppSpacing.lg), ClSkeleton(height: 120)]),
        ),
        error: (_, __) => ListView(padding: const EdgeInsets.all(AppSpacing.gutter), children: [
          const SizedBox(height: AppSpacing.xxl),
          ClErrorState(title: "Couldn't load your settings", onRetry: () => ref.invalidate(notificationPrefsProvider)),
        ]),
        data: (p) {
          NotificationPrefs copy({bool? polls, bool? discussions, bool? parties, bool? quiet}) => NotificationPrefs(
                polls: polls ?? p.polls,
                discussions: discussions ?? p.discussions,
                parties: parties ?? p.parties,
                quietEnabled: quiet ?? p.quietEnabled,
                quietStart: p.quietStart,
                quietEnd: p.quietEnd,
              );
          return ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl + bottom),
            children: [
              Text(
                'Choose what reaches your phone. Everything still shows in your notifications.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              Semantics(header: true, child: Text('Push notifications', style: AppTextStyles.h3)),
              const SizedBox(height: AppSpacing.md),
              ClCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Column(children: [
                  _Toggle(
                    title: 'Votes',
                    subtitle: 'When a club vote closes',
                    value: p.polls,
                    onChanged: (v) => _save(context, ref, copy(polls: v), {
                      'notificationPreferences': {'polls': v},
                    }),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _Toggle(
                    title: 'Discussions',
                    subtitle: 'Comments on films you suggested',
                    value: p.discussions,
                    onChanged: (v) => _save(context, ref, copy(discussions: v), {
                      'notificationPreferences': {'discussions': v},
                    }),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _Toggle(
                    title: 'Watch parties',
                    subtitle: 'New parties in your clubs',
                    value: p.parties,
                    // The backend has two keys for watch parties; set both.
                    onChanged: (v) => _save(context, ref, copy(parties: v), {
                      'notificationPreferences': {'watchparty': v, 'parties': v},
                    }),
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.section),
              Semantics(header: true, child: Text('Quiet hours', style: AppTextStyles.h3)),
              const SizedBox(height: AppSpacing.md),
              ClCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Column(children: [
                  _Toggle(
                    title: 'Quiet hours',
                    subtitle: 'No push notifications during these hours',
                    value: p.quietEnabled,
                    onChanged: (v) => _save(context, ref, copy(quiet: v), {
                      'quietHours': {'enabled': v},
                    }),
                  ),
                  if (p.quietEnabled) ...[
                    const Divider(height: 1, color: AppColors.border),
                    _TimeRow(label: 'From', value: p.quietStart, onTap: () => _pickTime(context, ref, p, start: true)),
                    const Divider(height: 1, color: AppColors.border),
                    _TimeRow(label: 'Until', value: p.quietEnd, onTap: () => _pickTime(context, ref, p, start: false)),
                  ],
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.title, required this.subtitle, required this.value, required this.onChanged});
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppTextStyles.label),
                Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
              ]),
            ),
            const SizedBox(width: AppSpacing.md),
            Switch(value: value, onChanged: onChanged, activeTrackColor: AppColors.purpleBadge),
          ]),
        ),
      );
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ClPressable(
        semanticLabel: '$label $value. Change',
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(children: [
            Expanded(child: Text(label, style: AppTextStyles.label)),
            Text(value, style: AppTextStyles.title.copyWith(color: AppColors.purpleText)),
          ]),
        ),
      );
}
