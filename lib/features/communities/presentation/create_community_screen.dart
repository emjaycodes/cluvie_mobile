import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  CreateCommunityScreenState createState() => CreateCommunityScreenState();
}

class CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _communityNameController = TextEditingController();
  final _communityDescriptionController = TextEditingController();

  @override
  void dispose() {
    _communityNameController.dispose();
    _communityDescriptionController.dispose();
    super.dispose();
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
                // Community Name
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

                // Community Description
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

                // Submit Button
                ClButton(
                  label: "Create Community",
                  onPressed: _createCommunity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
    void _createCommunity() {
    if (_formKey.currentState?.validate() ?? false) {
      // Handle community creation logic here
      final communityName = _communityNameController.text;
      final communityDescription = _communityDescriptionController.text;

      // For now, just print the values to the console
      print('Community Name: $communityName');
      print('Community Description: $communityDescription');

      // Optionally, navigate back or show a success message
      context.pop();
    }
  }
}



