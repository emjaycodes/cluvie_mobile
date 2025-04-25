// import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
// import 'package:flutter/material.dart';


// class CluvieGalleryPage extends StatefulWidget {
//   const CluvieGalleryPage({super.key});

//   @override
//   State<CluvieGalleryPage> createState() => _CluvieGalleryPageState();
// }

// class _CluvieGalleryPageState extends State<CluvieGalleryPage>
//     with SingleTickerProviderStateMixin {
//   int _selectedIndex = 0;
//   late final TabController _tabController;

//   @override
//   void initState() {
//     _tabController = TabController(length: 2, vsync: this);
//     super.initState();
//   }

//   void _onNavTap(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//     showCluvieSnackBar(
//       context: context,
//       message: 'Switched to tab $index',
//       type: ClSnackType.info,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const ClAppBar(title: 'Cluvie Widget Gallery', showBackButton: false),
//       bottomNavigationBar: ClBottomNavBar(
//         currentIndex: _selectedIndex,
//         onTap: _onNavTap,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("Buttons", style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             ClButton(label: 'Primary', onPressed: () {}),
//             const SizedBox(height: 8),
//             ClButton(label: 'Secondary', onPressed: () {}),

//             const SizedBox(height: 24),
//             const Text("Text Field", style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             ClTextField(
//               label: 'Username',
//               hintText: 'Enter your name',
//               controller: TextEditingController(),
//             ),

//             const SizedBox(height: 24),
//             const Text("Chips & Avatar", style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             Wrap(
//               spacing: 8,
//               children: const [
//                 ClChip(label: 'Thriller'),
//                 ClChip(label: 'Drama'),
//                 ClChip(label: 'Sci-Fi'),
//               ],
//             ),
//             const SizedBox(height: 12),
//             // const ClAvatar(url: 'https://image.tmdb.org/t/p/w500/ljsZTbVsrQSqZgWeep2B1QiDKuh.jpg', radius: 24, imageUrl: '',),

//             const SizedBox(height: 24),
//             const Text("Loading & Empty State", style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             const ClLoading(),
//             const SizedBox(height: 12),
//             const ClEmptyState(message: 'No content available'),

//             const SizedBox(height: 24),
//             const Text("Tab Bar", style: TextStyle(fontWeight: FontWeight.bold)),
//             ClTabBar(
//               tabs: const [Tab(text: 'Movies'), Tab(text: 'Votes')],
//               controller: _tabController,
//             ),

//             const SizedBox(height: 24),
//             ClButton(
//               label: 'Show Bottom Sheet',
//               onPressed: () {
//                 showModalBottomSheet(
//                   context: context,
//                   isScrollControlled: true,
//                   shape: const RoundedRectangleBorder(
//                     borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                   ),
//                   builder: (_) => const ClBottomSheet(
//                     title: 'Example Sheet',
//                     child: Center(child: Text('This is a bottom sheet!')),
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 12),
//             ClButton(
//               label: 'Show Dialog',
//               onPressed: () {
//                 showClDialog(
//                   context: context,
//                   title: 'Confirm',
//                   message: 'Do you want to continue?',
//                   onConfirm: () => showCluvieSnackBar(
//                     context: context,
//                     message: 'Confirmed!',
//                     type: ClSnackType.success,
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
