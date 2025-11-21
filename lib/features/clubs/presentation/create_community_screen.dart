// ignore_for_file: use_build_context_synchronously

import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<CreateCommunityScreen> createState() =>
      _CreateCommunityScreenConsumerState();
}

class _CreateCommunityScreenConsumerState
    extends ConsumerState<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _communityNameController = TextEditingController();
  final _communityDescriptionController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _communityNameController.dispose();
    _communityDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCommunity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final name = _communityNameController.text.trim();
    final description = _communityDescriptionController.text.trim();

    try {

      await ref.read(joinedCommunitiesProvider.notifier).createCommunity(
        name,
        description,
      );
      context.pop(); 
    } catch (e) {
      // Show snackbar or error dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Community"),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.clPadding,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _communityNameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter community name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a community name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _communityDescriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Describe your community',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a community description';
                    }
                    return null;
                  },
                  maxLines: 4,
                ),
                const SizedBox(height: 32),

                ClButton(
                  label: _isSubmitting ? "Creating..." : "Create Community",
                  onPressed: _isSubmitting ? (){} : _createCommunity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
