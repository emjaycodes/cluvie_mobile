import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Every icon in the app goes through this map so the icon set can be swapped
/// in one file (tokens.md: pin phosphor_icons, keep an indirection).
///
/// Regular weight at rest; `*Fill` variants for active / selected states.
abstract final class AppIcons {
  // Navigation
  static const IconData home = PhosphorIconsRegular.house;
  static const IconData homeFill = PhosphorIconsFill.house;
  static const IconData discover = PhosphorIconsRegular.compass;
  static const IconData discoverFill = PhosphorIconsFill.compass;
  static const IconData clubs = PhosphorIconsRegular.usersThree;
  static const IconData clubsFill = PhosphorIconsFill.usersThree;
  static const IconData profile = PhosphorIconsRegular.user;
  static const IconData profileFill = PhosphorIconsFill.user;
  static const IconData add = PhosphorIconsBold.plus;

  // Actions
  static const IconData back = PhosphorIconsRegular.caretLeft;
  static const IconData forward = PhosphorIconsRegular.caretRight;
  static const IconData close = PhosphorIconsRegular.x;
  static const IconData trash = PhosphorIconsRegular.trash;
  static const IconData search = PhosphorIconsRegular.magnifyingGlass;
  static const IconData share = PhosphorIconsRegular.shareNetwork;
  static const IconData more = PhosphorIconsRegular.dotsThree;
  static const IconData send = PhosphorIconsFill.paperPlaneRight;
  static const IconData attach = PhosphorIconsRegular.paperclip;
  static const IconData emoji = PhosphorIconsRegular.smiley;
  static const IconData settings = PhosphorIconsRegular.gear;
  static const IconData signOut = PhosphorIconsRegular.signOut;
  static const IconData check = PhosphorIconsBold.check;
  static const IconData edit = PhosphorIconsRegular.pencilSimple;
  static const IconData filter = PhosphorIconsRegular.slidersHorizontal;

  // Content
  static const IconData bell = PhosphorIconsRegular.bell;
  static const IconData bellFill = PhosphorIconsFill.bell;
  static const IconData chat = PhosphorIconsRegular.chatCircle;
  static const IconData chatFill = PhosphorIconsFill.chatCircle;
  static const IconData chats = PhosphorIconsRegular.chatsCircle;
  static const IconData heart = PhosphorIconsRegular.heart;
  static const IconData heartFill = PhosphorIconsFill.heart;
  static const IconData poll = PhosphorIconsRegular.chartBar;
  static const IconData pollFill = PhosphorIconsFill.chartBar;
  static const IconData ticket = PhosphorIconsRegular.ticket;
  static const IconData ticketFill = PhosphorIconsFill.ticket;
  static const IconData popcorn = PhosphorIconsRegular.popcorn;
  static const IconData clapper = PhosphorIconsRegular.filmSlate;
  static const IconData reel = PhosphorIconsRegular.filmReel;
  static const IconData filmStrip = PhosphorIconsRegular.filmStrip;
  static const IconData bookmark = PhosphorIconsRegular.bookmarkSimple;
  static const IconData bookmarkFill = PhosphorIconsFill.bookmarkSimple;
  static const IconData star = PhosphorIconsFill.star;
  static const IconData play = PhosphorIconsFill.play;
  static const IconData calendar = PhosphorIconsRegular.calendarBlank;
  static const IconData clock = PhosphorIconsRegular.clock;
  static const IconData pin = PhosphorIconsFill.pushPin;
  static const IconData crown = PhosphorIconsFill.crown;
  static const IconData trophy = PhosphorIconsRegular.trophy;
  static const IconData sparkle = PhosphorIconsFill.sparkle;
  static const IconData image = PhosphorIconsRegular.images;
  static const IconData user = PhosphorIconsRegular.userCircle;

  // Auth / forms
  static const IconData email = PhosphorIconsRegular.envelopeSimple;
  static const IconData lock = PhosphorIconsRegular.lock;
  static const IconData eye = PhosphorIconsRegular.eye;
  static const IconData eyeSlash = PhosphorIconsRegular.eyeSlash;

  // Status
  static const IconData success = PhosphorIconsFill.checkCircle;
  static const IconData error = PhosphorIconsFill.warningCircle;
  static const IconData warning = PhosphorIconsFill.warning;
  static const IconData info = PhosphorIconsFill.info;
  static const IconData loading = PhosphorIconsRegular.hourglassMedium;
  static const IconData offline = PhosphorIconsRegular.wifiSlash;
}
