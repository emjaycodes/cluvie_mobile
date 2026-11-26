import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:flutter/material.dart';

/// The snackbar after a join: welcome, welcome but stale, or why not.
void showJoinResult(BuildContext context, String clubName, ClubActionDone? done, ClubActionRefusal? refusal) {
  if (done != null) {
    ClSnackbar.show(
      context,
      message: done.refreshed ? 'Welcome to $clubName.' : "You joined $clubName. Couldn't refresh the club yet.",
      type: done.refreshed ? ClSnackbarType.success : ClSnackbarType.warning,
    );
    return;
  }
  ClSnackbar.show(
    context,
    message: switch (refusal) {
      ClubActionRefusal.notFound => '$clubName no longer exists.',
      ClubActionRefusal.unauthorised => 'Your session has ended. Sign in again to join.',
      _ => "Couldn't join $clubName. Check your connection and try again.",
    },
    type: ClSnackbarType.error,
  );
}
