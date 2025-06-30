import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

class SuggestMovieScreen extends StatelessWidget {
  const SuggestMovieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final clubs = [
      {
        'name': 'Cinephiles Unite 🎬',
        'members': '227 members',
        'time': '3 hr ago',
        'icon': Icons.group
      },
      {
        'name': 'Late Night Indies 🍊',
        'members': '178 members',
        'time': '5 h ago',
        'icon': Icons.person_2
      },
      {
        'name': 'Cinema Sundays 🌅',
        'members': '243 members',
        'time': '1d ago',
        'icon': Icons.wb_twilight
      },
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text('Suggest a Movie'),
        titleTextStyle: AppTextStyles.heading1.copyWith(color: Colors.white),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.search, color: Colors.white),
          //   onPressed: () {},
          // )
        ],
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Icon(Icons.cancel_outlined, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BuildSearchBar(),
              const SizedBox(height: 20),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network('https://image.tmdb.org/t/p/w500/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg', width: 60, height: 80, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Everything everywhere at once", style: AppTextStyles.heading2.copyWith(color: Colors.white), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text("2016 · 1 hr 56m · Sci-Fi", style: AppTextStyles.caption.copyWith(color: AppColors.darkTextPrimary)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              Text("Where would you like to suggest this movie?", style: AppTextStyles.body.copyWith(color: Colors.white)),
              const SizedBox(height: 12),
              ...clubs.map((club) => ClubCard(club: club)),
              const SizedBox(height: 16),
              Text("Set default club for suggestions", style: AppTextStyles.caption.copyWith(color: AppColors.accent)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text("Submit Suggestion", style: AppTextStyles.button.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  
  // Widget _BuildSearchBar() {
  //   return 
  // }
}

class BuildSearchBar extends StatelessWidget {
    const BuildSearchBar({super.key});
  
    @override
    Widget build(BuildContext context) {
      return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const TextField(
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search for any movie...',
          hintStyle: TextStyle(color: Colors.white54),
          icon: Icon(Icons.search, color: Colors.white54),
        ),
      ),
    );
    }
  }

class ClubCard extends StatelessWidget {
  final Map club;
  const ClubCard({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            child: Icon(club['icon'], color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(club['name'], style: AppTextStyles.body.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text("${club['members']} · ${club['time']}",
                    style: AppTextStyles.caption.copyWith(color: AppColors.darkTextPrimary)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
