# Little us — Privacy Policy

**Publication draft — complete the bracketed fields and verify your deployed service before publishing.**

Effective date: [PUBLICATION DATE]  
Operator: [DEVELOPER OR LEGAL ENTITY NAME]  
Privacy contact: [SUPPORT EMAIL]  
Account-deletion request page: [PUBLIC HTTPS DELETION URL]

Little us provides a private shared home for two people, daily question games, love notes, room decorations, and a reunion countdown. This policy describes version 1.0.0 with the supplied Supabase backend. If you add other services or change the implementation, update this policy before those changes reach users.

## 1. Information we process

**Connected accounts:** We process your email address, account identifier, authentication credentials through Supabase Auth, and your chosen first name. Passwords are handled by the authentication provider and are not displayed to your partner.

**Shared-home content:** We store your home membership, private invitation code and expiration, notes and their authors/timestamps, daily question answers and guesses, completion status, earned hearts, owned decorations, room color, and optional reunion date. Please do not put sensitive personal information into notes or game answers.

**Technical data:** The hosting and authentication provider may process IP addresses, request metadata, authentication events, and diagnostic/security logs to operate and secure the service. The operator must verify and disclose the categories actually logged by their deployment: [CONFIRMED LOG CATEGORIES].

**On your device:** The authentication SDK persists session tokens to keep you signed in. Demo mode stores its fictional home and any edits, notes, answers, and decoration choices locally using application preferences. Demo content is not uploaded to our shared-home service. Operating-system or browser backups may copy local application data according to your device settings.

This version does not request location, contacts, microphone, camera, or photo-library access. It does not contain advertising, behavioral analytics, payment, or in-app-purchase SDKs. It does not upload photos, record voice, or track your partner’s location.

## 2. Why we use information

We use account and home information to authenticate you, connect you to your chosen partner, synchronize shared content, run daily games, reveal answers after both participants submit, award shared hearts, remember your room, calculate the reunion countdown, respond to support requests, and protect the service from misuse.

## 3. Who can access information

Your paired partner can see your chosen name and shared-home content. A partner’s game answers and guesses are withheld by the server until both people submit that day’s round. Your sign-in email is not included in the shared-home response.

Supabase and its underlying service providers process information on the operator’s behalf for authentication, database hosting, and service operation. Authorized operators may access data when necessary for support, security, and maintenance. We do not sell personal data or use it for targeted advertising. Information may be disclosed where required by law or necessary to protect users and the service.

Invitation codes grant access to an unpaired home and must be kept private. They expire after seven days, can be renewed, and cannot be reused after a partner joins. Anyone to whom you deliberately give a valid code may join before it expires. Do not post a code publicly.

## 4. Security

Connected traffic uses HTTPS. The supplied backend blocks direct client table access and uses authenticated database functions to enforce home membership, answer visibility, and reward rules. These safeguards do not provide end-to-end encryption. No system can guarantee absolute security. Keep your device and account credentials secure. The operator is responsible for maintaining secure deployment settings and access controls.

## 5. Retention and deletion

Shared data remains in the active database until a participant deletes a note, erases the home, or deletes their account. The app displays up to 100 notes and the 30 most recent rounds; older rounds remain stored until the home is erased. Closing or uninstalling the app does not delete connected account data.

- **Individual notes:** Either partner can delete a shared note from Notes.
- **Shared home:** Us → Leave and erase shared home permanently removes the active home, all its notes and rounds, decorations, and reunion date for both people. Both sign-in accounts remain.
- **Account:** Us → Delete account removes the signed-in account and the entire shared home from the active database. The partner loses access to that home but retains their own sign-in account. A confirmation explains this consequence.
- **Without the app:** Request account deletion at [PUBLIC HTTPS DELETION URL] or contact [SUPPORT EMAIL] from your registered email. We may verify account ownership before acting. Requests are handled within [VERIFIED RESPONSE TIME].
- **Demo:** Us → Delete local demo data erases the locally saved demo. Merely exiting demo mode preserves it for later use.

Deleted active data may temporarily remain in provider backups and security logs. [STATE VERIFIED BACKUP RETENTION, LOG RETENTION, DELETION SCHEDULE, AND ANY LEGALLY REQUIRED EXCEPTIONS.] The operator must not publish this draft with unspecified retention periods.

Copies your partner has made outside the app, such as screenshots, are outside our control.

## 6. Your choices and rights

You may choose what content to share, delete notes, leave a shared home, and delete your account. Depending on where you live, you may have rights to access, correct, export, delete, or restrict processing of your personal information and to complain to a competent privacy authority. Contact [SUPPORT EMAIL] to make a request. [IF APPLICABLE, ADD VERIFIED LEGAL BASES AND REGION-SPECIFIC DISCLOSURES.]

## 7. Children

Little us is intended for adults aged 18 and older and is not directed to children. If you believe a child has supplied personal information, contact [SUPPORT EMAIL] so we can investigate and remove it where appropriate. The operator must configure the store audience and content rating consistently with the actual release.

## 8. International processing

Information is processed in [SUPABASE PROJECT REGION] and other locations used by the hosting provider. [DESCRIBE APPLICABLE TRANSFER SAFEGUARDS AFTER VERIFYING YOUR PROVIDER AGREEMENTS.]

## 9. Changes and contact

We will post revised policies at [PUBLIC HTTPS POLICY URL] and update the effective date. Material changes will be communicated as required. Questions or requests: [SUPPORT EMAIL], [OPERATOR POSTAL CONTACT IF REQUIRED].
