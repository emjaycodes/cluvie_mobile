
import 'package:cluvie_mobile/features/home/components/discussion_card.dart';
import 'package:cluvie_mobile/features/home/components/reaction_footer.dart';
import 'package:cluvie_mobile/features/home/components/upcoming_watchcard.dart';
import 'package:cluvie_mobile/features/home/components/voting_card.dart';
import 'package:cluvie_mobile/features/home/components/widgets/watch_card.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:flutter_svg/svg.dart';
import 'package:percent_indicator/percent_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SvgPicture.asset(
                'assets/images/cluvie_logo.svg',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'CLUVIE',
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
            ),
          ],
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.add_circle_outline),
        //     onPressed: () {},
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VotingCard(),
            SizedBox(height: 24),
            SectionTitle(title: "Top Discussions"),
            SizedBox(height: 12),
            DiscussionCard(
              title: "Oppenheimer",
              subtitle: "Christopher Nolan's magnum opus. Thoughts?",
              imageUrl:
                  'https://image.tmdb.org/t/p/w200/8QVDXDiOGHRcAD4oM6MXjE0osSj.jpg',
            ),
            DiscussionCard(
              title: "Mission: Impossible-Fallout",
              subtitle: "Most thrilling stunts ever filmed?",
              imageUrl:
                  'https://image.tmdb.org/t/p/w200/8QVDXDiOGHRcAD4oM6MXjE0osSj.jpg',
            ),
            WeeklyWatchlist(
              movies: [
                MovieCard(
                  title: 'The Batman',
                  posterUrl:
                      'https://image.tmdb.org/t/p/w500/74xTEgt7R36Fpooo50r9T25onhq.jpg',
                ),
                MovieCard(
                  title: 'Everything Everywhere All At Once',
                  posterUrl:
                      'https://image.tmdb.org/t/p/w500/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg',
                ),
                MovieCard(
                  title: 'Blade Runner 2049',
                  posterUrl:
                      'https://image.tmdb.org/t/p/w500/aMpyrCizvSdc0UIMblJ1srVgAEF.jpg',
                ),
              ],
            ),

            SizedBox(height: 24),
            SectionTitle(title: "Upcoming Watch Parties"),
            SizedBox(height: 12),
            UpcomingWatchCard(),
            SizedBox(height: 24),
            ReactionFooter(),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24),
                Text(
                  "Live Watch Party",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          CircularPercentIndicator(
                        radius: 60.0,
                        lineWidth: 8.0,
                        percent: 0.75,
                        center: Text(
                          "23:05",
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                        progressColor: AppColors.accent,
                        backgroundColor: Colors.grey[800]!,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "to watch",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      
                        ],
                      ),
                      SizedBox(width: 16),
                      
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/f1.png',
                          height: 200,
                        ),
                      ),
                      SizedBox(height: 8),
                      // Text(
                      //   "F1",
                      //   style: TextStyle(
                      //     fontSize: 16,
                      //     color: Colors.white,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // )
                    ],
                  ),
                ),
              ],
            ),

            // SizedBox(height: 24),
            // ClStatusBanner(
            //   type: ClStatusType.loading,
            //   message: "Loading data...",
            //   show: true,
            //   dismissible: true,
            // ),
          ],
        ),
      ),



      
      // bottomNavigationBar: ClBottomNavBar(),
      // BottomNavigationBar(
      //   currentIndex: 2,
      //   backgroundColor: AppColors.darkBackground,
      //   selectedItemColor: AppColors.accent,
      //   unselectedItemColor: AppColors.darkTextSecondary,
      //   type: BottomNavigationBarType.fixed,
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home_outlined),
      //       label: "Home",
      //     ),
      //     BottomNavigationBarItem(icon: Icon(Icons.search), label: "Discover"),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.add_circle_outline),
      //       label: "Suggest",
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.group_outlined),
      //       label: "Clubs",
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.person_outline),
      //       label: "Profile",
      //     ),
      //   ],
      // ),
    );
  }
}










