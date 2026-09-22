import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_app_bar.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_empty_state.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Notifications — CF-08
/// Route: /notifications  (deep-linkable via go_router, also /notifications-shell inside Shell)
/// Stub uses CL* empty states per spec, pull-to-refresh wired for future API.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;
  final List<Map<String, dynamic>> _items = [
    // Demo data — replaced by GET /api/notifications when backend mounted
    {
      'type': 'poll_expiring',
      'title': 'Poll expiring in 2h',
      'body': '“Cinema Sundays” poll closes soon — cast your vote!',
      'time': '2h ago',
      'read': false,
    },
    {
      'type': 'new_comment',
      'title': 'New comment on your suggestion',
      'body': 'Ava: “Oppenheimer final scene — let’s discuss!”',
      'time': '5h ago',
      'read': false,
    },
    {
      'type': 'watch_party',
      'title': 'Watch party scheduled',
      'body': '“Past Lives” — tomorrow 8pm · RSVP now',
      'time': '1d ago',
      'read': true,
    },
  ];

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _isLoading = false);
  }

  void _markAllRead() {
    setState(() {
      for (final n in _items) {
        n['read'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  int get _unread => _items.where((e) => e['read'] == false).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ClAppBar(
        title: 'Notifications',
        actions: [
          if (_unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read', style: TextStyle(color: AppColors.accent)),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.accent,
        child: _items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  ClEmptyState(
                    message: 'No notifications yet.\nWe’ll notify you about votes, comments & watch parties.',
                    icon: Icons.notifications_none_rounded,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('$_unread unread',
                                style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                    );
                  }
                  final n = _items[index - 1];
                  final isUnread = n['read'] == false;
                  IconData icon;
                  Color iconBg;
                  switch (n['type']) {
                    case 'poll_expiring':
                      icon = Icons.how_to_vote_rounded;
                      iconBg = AppColors.accent;
                      break;
                    case 'new_comment':
                      icon = Icons.chat_bubble_rounded;
                      iconBg = AppColors.success;
                      break;
                    default:
                      icon = Icons.live_tv_rounded;
                      iconBg = AppColors.cinematicPurple;
                  }
                  return Material(
                    color: isUnread ? Colors.white.withOpacity(0.06) : AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        // Deep link per notification type
                        if (n['type'] == 'poll_expiring') {
                          context.push('/communities/demo-community/vote');
                        } else if (n['type'] == 'new_comment') {
                          context.push('/discussionThread');
                        } else {
                          context.push('/watchParty');
                        }
                        setState(() => n['read'] = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isUnread ? AppColors.accent.withOpacity(0.35) : Colors.white10,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: iconBg.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                              child: Icon(icon, color: iconBg, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(n['title'],
                                            style: AppTextStyles.body.copyWith(
                                                color: Colors.white, fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500)),
                                      ),
                                      if (isUnread)
                                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(n['body'], style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
                                  const SizedBox(height: 6),
                                  Text(n['time'], style: AppTextStyles.caption.copyWith(color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
