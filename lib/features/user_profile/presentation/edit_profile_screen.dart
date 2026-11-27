import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/user_profile/data/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Edit your name, bio and avatar (`/profile/edit`).
///
/// Gold budget: the Save button (the screen's one action).
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    return Scaffold(
      appBar: const ClAppBar(title: 'Edit profile', fallbackRoute: '/profile'),
      body: profile.when(
        skipLoadingOnRefresh: profile.hasValue,
        skipError: profile.hasValue,
        loading: () => Semantics(
          label: 'Loading your profile',
          liveRegion: true,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl),
            children: const [
              ClSkeleton(height: 64),
              SizedBox(height: AppSpacing.lg),
              ClSkeleton(height: 120),
              SizedBox(height: AppSpacing.lg),
              ClSkeleton(height: 64),
              SizedBox(height: AppSpacing.xl),
              ClSkeleton(height: 48),
            ],
          ),
        ),
        error: (_, __) => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, AppSpacing.xxl),
          children: [
            ClErrorState(
              title: "Couldn't load your profile",
              compact: true,
              onRetry: () => ref.invalidate(myProfileProvider),
            ),
          ],
        ),
        data: (p) => _EditProfileForm(profile: p),
      ),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});
  final MyProfile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9_.]{3,30}$');

  late final TextEditingController _username;
  late final TextEditingController _bio;
  late final TextEditingController _avatar;
  bool _saving = false;
  String? _usernameTaken;
  String? _banner;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.profile.username);
    _bio = TextEditingController(text: widget.profile.bio);
    _avatar = TextEditingController(text: widget.profile.avatarUrl ?? '');
  }

  @override
  void dispose() {
    _username.dispose();
    _bio.dispose();
    _avatar.dispose();
    super.dispose();
  }

  String get _usernameValue => _username.text.trim();

  String? get _usernameError {
    if (_usernameValue.isEmpty) return 'Enter a username';
    if (!_usernamePattern.hasMatch(_usernameValue)) {
      return 'Username must be 3–30 letters, numbers, _ or .';
    }
    return null;
  }

  // The server trims before checking the 160 limit, so count the same way.
  int get _bioLength => _bio.text.trim().length;

  String? get _bioError =>
      _bioLength > 160 ? 'Use 160 characters or fewer ($_bioLength used)' : null;

  String? get _avatarError {
    final value = _avatar.text.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'Avatar URL must start with https://';
    }
    if (value.length > 500) return 'Avatar URL is too long';
    return null;
  }

  bool get _dirty =>
      _usernameValue != widget.profile.username ||
      _bio.text != widget.profile.bio ||
      _avatar.text.trim() != (widget.profile.avatarUrl ?? '');

  bool get _valid => _usernameError == null && _bioError == null && _avatarError == null;

  bool get _canSave => !_saving && _dirty && _valid;

  void _changed() {
    if (_usernameTaken != null || _banner != null) {
      setState(() {
        _usernameTaken = null;
        _banner = null;
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _usernameTaken = null;
      _banner = null;
    });
    final refusal = await updateMyProfile(
      ref,
      username: _usernameValue,
      bio: _bio.text.trim(),
      avatarUrl: _avatar.text.trim(),
    );
    if (!mounted) return;
    if (refusal == null) {
      ClSnackbar.show(context, message: 'Profile updated.', type: ClSnackbarType.success);
      context.pop();
      return;
    }
    if (refusal == ProfileUpdateError.usernameTaken) {
      setState(() {
        _saving = false;
        _usernameTaken = 'That username is taken. Try another.';
      });
      return;
    }
    if (refusal == ProfileUpdateError.invalidProfile) {
      setState(() {
        _saving = false;
        _banner = "Some details weren't accepted. Check each field and try again.";
      });
      return;
    }
    setState(() => _saving = false);
    ClSnackbar.show(context, message: "Couldn't save your profile. Try again.", type: ClSnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl + bottom),
      children: [
        Text(
          'This is how other Cluvie members see you.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        ClTextField(
          label: 'Username',
          controller: _username,
          hintText: 'e.g. cinephile_supreme',
          helperText: '3–30 letters, numbers, _ or .',
          errorText: _usernameTaken ?? _usernameError,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _changed(),
        ),
        const SizedBox(height: AppSpacing.lg),
        ClTextField(
          label: 'Bio',
          controller: _bio,
          hintText: 'A line or two about the films you love',
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          helperText: '$_bioLength / 160',
          errorText: _bioError,
          onChanged: (_) => _changed(),
        ),
        const SizedBox(height: AppSpacing.lg),
        ClTextField(
          label: 'Avatar URL',
          controller: _avatar,
          hintText: 'https://example.com/me.jpg',
          keyboardType: TextInputType.url,
          helperText: 'Optional. Leave blank to remove your picture.',
          errorText: _avatarError,
          textInputAction: TextInputAction.done,
          onChanged: (_) => _changed(),
          onSubmitted: (_) => _save(),
        ),
        if (_banner != null) ...[
          const SizedBox(height: AppSpacing.lg),
          ClStatusBanner(type: ClStatusType.error, message: _banner!),
        ],
        const SizedBox(height: AppSpacing.xl),
        ClButton(
          label: 'Save',
          variant: ClButtonVariant.primary,
          isLoading: _saving,
          onPressed: _canSave ? _save : null,
        ),
      ],
    );
  }
}
