# Mistress Alarm

A dark, red-accented alarm app with custom wake-up commands, multiple alarms, vibration, and a clear dismiss action. Android APK builds automatically through GitHub Actions.

## Download on Android
1. Open the repository on GitHub and choose **Actions**.
2. Open the latest successful **Build Android APK** run.
3. Under **Artifacts**, download `mistress-alarm-android` and unzip it.
4. Open `app-release.apk` on your phone and approve installation from your browser/files app if Android asks.
5. Allow notifications and exact alarms when prompted by Android.

For alarms to ring consistently, permit notifications and alarms/reminders in Android settings. Battery restrictions vary by phone maker.

## Build locally
Install Flutter, then run `flutter pub get` and `flutter build apk --release`.
