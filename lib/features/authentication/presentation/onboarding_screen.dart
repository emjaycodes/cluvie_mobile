import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
import 'package:cluvie_mobile/features/authentication/components/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();
  int _curr = 0;

  final List<String> _texts = [
    "Discover and vote on movies with your community",
    "Join discussions, share reviews, and suggest films to watch.",
    "Host watch parties and experience films together, no matter the distance.",
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: controller,
        physics: BouncingScrollPhysics(),
        itemCount: _texts.length,
        onPageChanged: (index) {
          setState(() {
            _curr = index;
          });
        },
        itemBuilder: (context, index) {
          return Pages(text: _texts[index], currentPage: _curr, isLastPage: index == _texts.length - 1,);
        },
      ),
    );
  }
}

class Pages extends StatelessWidget {
  final String text;
  final int currentPage;
  final bool isLastPage;
  const Pages({super.key, required this.text, required this.currentPage, required this.isLastPage,});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  AppSpacing.clPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          
            Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 40, right: 20),
        child:  Text(
              "skip",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.cinematicPurple),
            ),
      ),
    ),
    Spacer(),
          Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
    
          Spacer(),
          DotsIndicatorWidget(currentPage: currentPage, pageLength: 3),

           if (isLastPage)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child:ClButton(
                    label: "Get Started",
                  onPressed: () => context.pushNamed(RouteNames.signup),

                  ),
                ),
        ],
      ),
    );
  }
}
