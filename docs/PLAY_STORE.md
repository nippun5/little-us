# Little us — Play Store kit

App name: **Little us**

Short description (under 80 characters):
**A cozy home for two. Play, leave love notes, and count down to your next hello.**

Full description:

A little home. A whole lot of us.

Little us is a cozy place for you and your favorite person—even when you are far apart. Share a virtual home, discover the little things about each other, and make space for everyday connection.

KNOW ME BETTER
Answer three daily questions about yourself and guess your partner’s answers. Play whenever you have a moment. Answers stay a surprise until you both finish.

MAKE A HOME TOGETHER
Earn shared hearts for completing a round together, then choose a sofa color for your home. You earn hearts for participating, not for getting everything right.

LEAVE A LITTLE LOVE NOTE
Pin a sweet message, a tiny memory, or an everyday thought to your shared notes board.

LOOK FORWARD TO YOUR NEXT HELLO
Set your next meeting date and enjoy a countdown to being together again.

MADE FOR TWO
Create an account, privately invite your partner, and settle into your shared home. You can also explore an offline demo before pairing.

No ads. No in-app purchases. No location tracking.

An internet connection and two accounts are needed for shared features. The demo runs locally. Daily questions reset at midnight UTC; the initial 21-question collection rotates weekly. Connected homes refresh periodically while the app is open.

## Asset files

| File | Size | Suggested alt text |
|---|---|---|
| app-icon-512.png | 512 × 512 | Cream house with a lilac roof and heart-shaped doorway on coral |
| feature-graphic-1024x500.png | 1024 × 500 | Little us: A little home. A whole lot of us. Beside a cozy peach sofa |
| screenshot-01-home.png | 1080 × 1920 | A private illustrated room with a question-game card |
| screenshot-02-play.png | 1080 × 1920 | Three daily couple questions with a shared completion reward |
| screenshot-03-notes.png | 1080 × 1920 | A personal message on the shared love-notes board |

Screenshots are real Flutter renderer captures using fictional demo data and no Android status bar. Recapture on the signed Android build for the final store submission. Generated feature artwork is promotional illustration, not a claim that the app uses the same rendering style.

## Release requirements to finish

1. Supply your unique Android application ID and upload signing key; build and test the native release.
2. Deploy the SQL, configure Supabase Auth, and perform two-device tests. Add a tested password-recovery flow.
3. Complete and publish the supplied privacy policy and external account-deletion page at public HTTPS URLs. Replace bracketed fields. Link the completed full policy from the app.
4. Complete Play Console Data safety for the deployed build. Account email/name/IDs and user-provided notes/answers are processed by the backend. Determine provider technical-log disclosures from the actual configuration. Do not declare “no data collected” for connected mode.
5. Set the intended adult audience and appropriate content rating. Complete reviewer app-access instructions with working review accounts; do not place real credentials in this source package.
6. Confirm the current target-API and testing requirements shown in your own Play Console. The supplied Android project follows Flutter’s configured target SDK and is not evidence that a future Play deadline is met.
7. Verify account deletion from inside the app and via your external request channel, including documented backup/log retention. Test large text, long names, offline failures, midnight UTC rollover, app resume, and invite expiry on devices.

Official references checked during preparation:
- https://support.google.com/googleplay/android-developer/answer/9866151
- https://support.google.com/googleplay/android-developer/answer/10144311
- https://support.google.com/googleplay/android-developer/answer/13327111
