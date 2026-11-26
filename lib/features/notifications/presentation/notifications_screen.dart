import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/core/utils/relative_time.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/notifications/data/notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Notifications (`/notifications`): the signed-in user's own, newest
/// first, from `GET /notifications`.
///
/// * Tapping one marks it read (`PATCH /:id/read`) and opens what it's
///   about, when the app has a screen for it. Others aren't tappable.
/// * "Clear all" deletes them (`DELETE /clear`) after confirming. There is
///   no "mark all read" endpoint, so there is no such button.
/// * No settings gear: the backend has preferences but no route to change
///   them.
///
/// Gold budget: none.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String? _opening;

  Future<void> _open(AppNotification n) async {
    ref.read(notificationsProvider.notifier).markRead(n.id);
    final target = targetFor(n.link, me: ref.read(currentUserIdProvider).valueOrNull);
    if (target == null || _opening != null) return;
    setState(() => _opening = n.id);
    String? route;
    try {
      route = await resolve(ref.read(apiClientProvider), target);
    } catch (_) {
      route = null;
    }
    if (!mounted) return;
    setState(() => _opening = null);
    if (route == null) {
      ClSnackbar.show(context, message: "Couldn't open this. It may have been removed.", type: ClSnackbarType.error);
      return;
    }
    context.push(route);
  }

  void _confirmClear() => showClDialog(
        context: context,
        title: 'Clear all notifications?',
        message: "They'll be deleted. You can't undo this.",
        confirmText: 'Clear all',
        closeText: 'Keep them',
        showConfirm: true,
        destructive: true,
        onConfirm: () async {
          try {
            await ref.read(notificationsProvider.notifier).clearAll();
          } catch (_) {
            if (mounted) ClSnackbar.show(context, message: "Couldn't clear them. Try again.", type: ClSnackbarType.error);
          }
        },
      );

  Future<void> _refresh() async {
    final had = ref.read(notificationsProvider).hasValue;
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
    try {
      await ref.read(notificationsProvider.future);
    } catch (_) {
      if (had && mounted) {
        ClSnackbar.show(context, message: "Couldn't refresh. Showing earlier notifications.", type: ClSnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(notificationsProvider);
    final me = ref.watch(currentUserIdProvider).valueOrNull;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final hasItems = items.valueOrNull?.isNotEmpty ?? false;

    Widget scroll(List<Widget> children) => RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.purple,
          backgroundColor: AppColors.surfaceRaised,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xxl + bottom),
            children: children,
          ),
        );

    Widget section(String title, List<AppNotification> list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
              child: Semantics(header: true, child: Text(title, style: AppTextStyles.h3)),
            ),
            ClCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final (i, n) in list.indexed) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                  _Row(
                    n: n,
                    opening: _opening == n.id,
                    onTap: targetFor(n.link, me: me) != null || !n.isRead ? () => _open(n) : null,
                  ),
                ],
              ]),
            ),
          ],
        );

    return Scaffold(
      appBar: ClAppBar(
        title: 'Notifications',
        frosted: true,
        fallbackRoute: '/home',
        actions: [
          if (hasItems)
            ClIconButton(icon: AppIcons.trash, tooltip: 'Clear all', onPressed: _confirmClear),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: items.when(
        skipLoadingOnRefresh: items.hasValue,
        skipError: items.hasValue,
        loading: () => Semantics(
          label: 'Loading notifications',
          liveRegion: true,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                const ClSkeletonRow(thumbWidth: 40, thumbHeight: 40),
              ],
            ],
          ),
        ),
        error: (_, __) => scroll([
          const SizedBox(height: AppSpacing.xxl),
          ClErrorState(title: "Couldn't load notifications", onRetry: () => ref.invalidate(notificationsProvider)),
        ]),
        data: (list) {
          if (list.isEmpty) {
            return scroll(const [
              SizedBox(height: AppSpacing.xxl),
              ClEmptyState(
                illustration: ClIllustration.notifications,
                title: "You're all caught up",
                message: 'Votes, comments and watch parties in your clubs will show up here.',
              ),
            ]);
          }
          final unread = [for (final n in list) if (!n.isRead) n];
          final read = [for (final n in list) if (n.isRead) n];
          return scroll([
            if (unread.isNotEmpty) section('New', unread),
            if (read.isNotEmpty) section(unread.isEmpty ? 'All read' : 'Earlier', read),
          ]);
        },
      ),
    );
  }
}

IconData _iconFor(NotificationKind k) => switch (k) {
      NotificationKind.follow => AppIcons.user,
      NotificationKind.comment || NotificationKind.discussion => AppIcons.chat,
      NotificationKind.vote => AppIcons.heart,
      NotificationKind.suggestion => AppIcons.popcorn,
      NotificationKind.poll => AppIcons.poll,
      NotificationKind.watchParty => AppIcons.ticket,
      NotificationKind.alert => AppIcons.info,
    };

class _Row extends StatelessWidget {
  const _Row({required this.n, required this.opening, required this.onTap});
  final AppNotification n;
  final bool opening;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !n.isRead;
    final row = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unread ? AppColors.purpleContainer : AppColors.surfaceRaised,
          ),
          child: Icon(_iconFor(n.kind), size: 20, color: unread ? AppColors.purpleText : AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FitWordsText(n.title, styles: unread ? const [AppTextStyles.label, AppTextStyles.bodySm] : const [AppTextStyles.body, AppTextStyles.bodySm]),
            if (n.message.isNotEmpty && n.message != n.title) ...[
              const SizedBox(height: AppSpacing.xxs),
              FitWordsText(
                n.message,
                styles: [
                  AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(timeAgo(n.createdAt), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
        if (opening)
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.sm),
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple)),
          )
        else if (unread)
          Container(
            margin: const EdgeInsets.only(left: AppSpacing.sm, top: 6),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.purple),
          ),
      ]),
    );
    final label = [
      if (unread) 'Unread',
      n.title,
      if (n.message.isNotEmpty && n.message != n.title) n.message,
      timeAgoSpoken(n.createdAt),
    ].join('. ');
    if (onTap == null) return Semantics(label: label, excludeSemantics: true, child: row);
    return ClPressable(semanticLabel: label, onTap: onTap, child: row);
  }
}
