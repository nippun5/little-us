/// Only known destinations are accepted from FCM data payloads.
enum PushDestination { fridgeNote, sameThought, doodle }

PushDestination? pushDestinationFromData(Map<String, dynamic> data) {
  switch (data['kind']) {
    case 'fridge_note':
      return PushDestination.fridgeNote;
    case 'same_thought':
      return PushDestination.sameThought;
    case 'doodle_started':
    case 'doodle_finished':
      return PushDestination.doodle;
    default:
      return null;
  }
}

int tabForPushDestination(PushDestination destination) =>
    destination == PushDestination.fridgeNote ? 2 : 1;

String labelForPushDestination(PushDestination destination) => switch (destination) {
      PushDestination.fridgeNote => 'A new fridge note is waiting for you.',
      PushDestination.sameThought => 'Your person invited you to Same Thought.',
      PushDestination.doodle => 'Your partner shared a doodle update.',
    };
