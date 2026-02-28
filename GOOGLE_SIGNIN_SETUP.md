# Google Sign-In Setup Guide

## Current Issue
Google Sign-In is not working because the OAuth client configuration is missing from the Firebase project.

## Error Details
- `SecurityException: Unknown calling package name 'com.google.android.gms'`
- Empty `oauth_client` array in `google-services.json`
- Google API Manager failures

## Solution Steps

### 1. Enable Google Sign-In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `mydarzi-app`
3. Navigate to **Authentication** → **Sign-in method**
4. Click on **Google** provider
5. Click **Enable**
6. Set the project support email (required)
7. Click **Save**

### 2. Configure OAuth 2.0 Client IDs

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: `mydarzi-app`
3. Navigate to **APIs & Services** → **Credentials**
4. Click **+ CREATE CREDENTIALS** → **OAuth 2.0 Client IDs**

#### Create Android OAuth Client:
- Application type: **Android**
- Name: `Mydarzi App Android`
- Package name: `com.mydarzi.godarzi`
- SHA-1 certificate fingerprint: You need to get this from your keystore

#### Get SHA-1 Fingerprint:
```bash
# For debug keystore (development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release keystore (production)
keytool -list -v -keystore /path/to/your/release.keystore -alias your_alias_name
```

### 3. Update Firebase Configuration

After creating the OAuth client:
1. Download the new `google-services.json` from Firebase Console
2. Replace the current file at `android/app/google-services.json`
3. The new file should have OAuth client configuration

### 4. Re-enable Google Sign-In in App

Once configured, update `lib/screen/firebase_login_screen.dart`:

```dart
Future<void> _handleGoogleSignIn() async {
  final authProvider =
      Provider.of<FirebaseAuthProvider>(context, listen: false);
  final success = await authProvider.signInWithGoogle();

  if (success && mounted) {
    Navigator.pushReplacementNamed(context, '/home');
  }
}
```

### 5. Test Configuration

1. Clean and rebuild the app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. Try Google Sign-In functionality

## Current Workaround

Google Sign-In is temporarily disabled with a user-friendly message. Email/password authentication works correctly.

## Email/Password Authentication

✅ **Working Features:**
- User registration with email/password
- User login with email/password
- Password reset functionality
- User data storage in Firestore

## Next Steps

1. Follow the configuration steps above
2. Test Google Sign-In functionality
3. Remove the temporary workaround message

## Additional Notes

- The app package name is correctly set to `com.mydarzi.godarzi`
- Firebase project ID is `mydarzi-app`
- All other Firebase services (Auth, Firestore, Storage) are working correctly
