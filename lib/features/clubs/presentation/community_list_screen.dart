// ignore_for_file: deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_empty_state.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

/// Communities List — CF-04
/// Shows member count, role badge, last activity, empty CTA.
/// Pull-to-refresh + invite code entry.
class CommunityListScreen extends ConsumerStatefulWidget {
  const CommunityListScreen({super.key});
  @override
  ConsumerState<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends ConsumerState<CommunityListScreen> {
  final _inviteCtrl = TextEditingController();

  @override
  void dispose() {
    _inviteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allCommunitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Communities', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () => context.push('/notifications')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        onPressed: () => context.push('/createCommunity'),
        icon: const Icon(Icons.add),
        label: const Text('Create', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () => ref.refresh(allCommunitiesProvider.future),
          child: Padding(
            padding: AppSpacing.clPadding,
            child: Column(
              children: [
                // Invite code handling
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _inviteCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter invite code (e.g. CLUV-AB12)',
                          hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          prefixIcon: const Icon(Icons.vpn_key_outlined, color: Colors.white38, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final code = _inviteCtrl.text.trim();
                        if (code.length < 4) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid invite code')));
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Joining with code $code…')));
                        _inviteCtrl.clear();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Join', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: allAsync.when(
                    loading: () => ListView.builder(
                      itemCount: 3,
                      itemBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Shimmer.fromColors(baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700, child: Container(height: 92, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                      ),
                    ),
                    error: (e, _) => ListView(children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.4))),
                        child: Column(children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 36),
                          const SizedBox(height: 10),
                          Text("Couldn't load communities — tap to retry", style: AppTextStyles.body.copyWith(color: AppColors.error, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: () => ref.refresh(allCommunitiesProvider.future), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white), child: const Text('Retry')),
                        ]),
                      ),
                    ]),
                    data: (communities) {
                      if (communities.isEmpty) {
                        return ListView(children: [
                          const SizedBox(height: 40),
                          const ClEmptyState(message: 'No communities yet.', icon: Icons.groups_rounded),
                          const SizedBox(height: 8),
                          Text('Create your first film club or join with an invite code.', style: AppTextStyles.body.copyWith(color: AppColors.darkTextSecondary), textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          ClButton(onPressed: () => context.push('/createCommunity'), label: 'Create a Community'),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: BorderSide(color: AppColors.accent.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('Enter invite code above'),
                          ),
                        ]);
                      }
                      return ListView.separated(
                        itemCount: communities.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final community = communities[index];
                          final isAdmin = community.admins.isNotEmpty;
                          final memberCount = community.members.length;
                          final lastActivity = 'Active 2h ago';
                          return InkWell(
                            onTap: () => context.push('/communities/${community.id}'),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
                              child: Row(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: 'https://picsum.photos/seed/${community.id}/80/80',
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    placeholder: (c, u) => Shimmer.fromColors(baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700, child: Container(width: 56, height: 56, color: Colors.white)),
                                    errorWidget: (_, __, ___) => Container(width: 56, height: 56, color: Colors.white10, child: const Icon(Icons.group, color: Colors.white30)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(child: Text(community.name ?? 'Untitled', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(color: isAdmin ? AppColors.accent.withOpacity(0.18) : Colors.white10, borderRadius: BorderRadius.circular(20)),
                                        child: Text(isAdmin ? 'ADMIN' : 'MEMBER', style: AppTextStyles.caption.copyWith(color: isAdmin ? AppColors.accent : Colors.white70, fontWeight: FontWeight.w800, fontSize: 9)),
                                      ),
                                    ]),
                                    const SizedBox(height: 3),
                                    Text('$memberCount members · $lastActivity', style: AppTextStyles.caption.copyWith(color: Colors.white54, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text(community.description ?? 'Film club', style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ]),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                              ]),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
