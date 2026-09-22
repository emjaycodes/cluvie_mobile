// ignore_for_file: use_build_context_synchronously
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Create community — validates 3–40 chars per PRD-010 / US-008.
class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});
  @override
  ConsumerState<CreateCommunityScreen> createState() => _CreateCommunityScreenConsumerState();
}

class _CreateCommunityScreenConsumerState extends ConsumerState<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(joinedCommunitiesProvider.notifier).createCommunity(_nameCtrl.text.trim(), _descCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Community "${_nameCtrl.text.trim()}" created ✓'), backgroundColor: AppColors.success));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nameLen = _nameCtrl.text.length;
    return Scaffold(
      appBar: AppBar(title: Text('Create Community', style: AppTextStyles.heading2.copyWith(color: Colors.white))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.clPadding,
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.10), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Name must be 3–40 characters, unique per owner. You become admin.', style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600))),
                ]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                maxLength: 40,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Community name *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'e.g. Cinema Sundays',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.accent)),
                  counterText: '$nameLen / 40',
                  counterStyle: TextStyle(color: nameLen > 40 || (nameLen > 0 && nameLen < 3) ? AppColors.error : Colors.white38, fontSize: 11),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Please enter a community name';
                  if (t.length < 3) return 'Name must be at least 3 characters';
                  if (t.length > 40) return 'Name must be at most 40 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'What is this club about?',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.accent)),
                ),
                validator: (v) {
                  if (v != null && v.length > 200) return 'Description max 200 chars';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text('You can generate an invite code after creation to add members.', style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ClButton(label: _isSubmitting ? 'Creating…' : 'Create Community', onPressed: _isSubmitting ? () {} : _create, isLoading: _isSubmitting),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: () => context.pop(), style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: BorderSide(color: Colors.white12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Cancel')),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
