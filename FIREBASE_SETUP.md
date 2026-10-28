# Firebase setup (run in Chrome, free Spark plan, no credit card)

1. Open https://console.firebase.google.com and create a project (Spark plan).
2. **Build > Authentication > Get started > Sign-in method**: enable **Email/Password**.
3. **Build > Firestore Database > Create database**: choose a region (for example
   asia-southeast1) and **production mode**. Open the **Rules** tab, paste the content of
   `firestore.rules` from this folder and press **Publish**.
4. Install the tools once:
   - Node.js, then `npm install -g firebase-tools` and `firebase login`
   - `dart pub global activate flutterfire_cli`
5. In the project folder run:
   ```
   flutter pub add firebase_core firebase_auth cloud_firestore
   flutterfire configure --platforms=web
   ```
   Pick your Firebase project. This **overwrites `lib/firebase_options.dart`** (the placeholder).
6. Run: `flutter run -d chrome`
7. Register an account, open the **Profile** tab and press **Seed demo videos (dev only)**
   (visible only in debug mode), then refresh Home.

Note: Cloud Storage (real video files) needs the paid Blaze plan since February 2026, so this
step only uses Authentication and Firestore. Videos are referenced by URL for now.
