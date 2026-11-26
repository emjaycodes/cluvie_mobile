import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const kClubNameMin = 3;
const kClubNameMax = 40;
const kClubDescriptionMax = 200;

String? validateClubName(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return 'Give your club a name';
  if (t.length < kClubNameMin) return 'Use at least $kClubNameMin characters';
  if (t.length > kClubNameMax) return 'Use at most $kClubNameMax characters';
  return null;
}

/// The backend requires a description.
String? validateClubDescription(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return 'Say what the club is about';
  if (t.length > kClubDescriptionMax) return 'Use at most $kClubDescriptionMax characters';
  return null;
}

/// Create a club (`/createCommunity`). The creator becomes its owner and
/// lands on the new club.
///
/// Gold budget: "Create club".
class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});
  @override
  ConsumerState<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends ConsumerState<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _descFocus = FocusNode();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_submitting) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final name = _nameCtrl.text.trim();
    try {
      final club = await ref.read(joinedCommunitiesProvider.notifier).createCommunity(name, _descCtrl.text.trim());
      if (!mounted) return;
      ClSnackbar.show(context, message: '$name is ready. Friends can find it under Clubs.', type: ClSnackbarType.success);
      if (club.id != null) {
        context.pushReplacement('/communities/${club.id}');
      } else {
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = "Couldn't create the club. Check your connection and try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nameLen = _nameCtrl.text.trim().length;
    final descLen = _descCtrl.text.trim().length;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: const ClAppBar(title: 'New club', frosted: true, fallbackRoute: '/communities'),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl + bottom),
          children: [
            Text(
              "Start a club for the people you watch films with. You'll be its owner.",
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            ClTextField(
              label: 'Club name',
              controller: _nameCtrl,
              hintText: 'e.g. Cinema Sundays',
              prefixIcon: AppIcons.clubs,
              textInputAction: TextInputAction.next,
              helperText: '$nameLen / $kClubNameMax',
              inputFormatters: [LengthLimitingTextInputFormatter(kClubNameMax)],
              validator: validateClubName,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _descFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.lg),
            ClTextField(
              label: 'What is it about?',
              controller: _descCtrl,
              focusNode: _descFocus,
              hintText: 'e.g. One film a week, then we argue about it',
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              helperText: '$descLen / $kClubDescriptionMax',
              inputFormatters: [LengthLimitingTextInputFormatter(kClubDescriptionMax)],
              validator: validateClubDescription,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_error != null) ...[
              ClStatusBanner(type: ClStatusType.error, message: _error!),
              const SizedBox(height: AppSpacing.lg),
            ],
            ClButton(
              label: 'Create club',
              variant: ClButtonVariant.primary,
              isLoading: _submitting,
              onPressed: _submitting ? null : _create,
            ),
          ],
        ),
      ),
    );
  }
}
