# Firebase & Platform Configuration for OAuth

## Prerequisites

This guide assumes you have:
- Google Cloud Console account
- Flutter project already set up for Android and iOS

## Google Sign-In Setup

### 1. Google Cloud Console Configuration

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing HitMeUp project
3. Enable the Google Identity API:
   - Search for "Google Identity" in APIs
   - Click "Google Identity" → Enable

4. Create OAuth 2.0 Credentials:
   - Go to Credentials (left sidebar)
   - Click "Create Credentials" → OAuth client ID
   - Choose "Android" application type

### 2. Android Configuration

1. Get your Android app's SHA-1 fingerprint:
```bash
cd ./android
./gradlew signingReport
# On Windows PowerShell use:
.\gradlew.bat signingReport
```

2. In Google Cloud Console:
    - Add SHA-1 certificate fingerprint
    - Add package name: `com.hitmeup.app`

3. Download the `google-services.json` file:
   - Only needed if you use Firebase services.
   - If you are only using the `google_sign_in` package (no Firebase), you can skip this.

4. Update `android/app/build.gradle.kts` (only if you use Firebase):
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
```

5. Update `android/settings.gradle.kts` (only if you use Firebase):
```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

If you are not using Firebase Authentication/Analytics/Messaging, skip Step 4 and Step 5.

### 3. iOS Configuration

1. In Google Cloud Console, create iOS OAuth credentials:
    - Choose "iOS" application type
    - Bundle ID: `com.hitmeup.app` (match your Xcode bundle ID)
    - Team ID: Your Apple Team ID only if you later enable Apple Sign-In

2. Download the `GoogleService-Info.plist` only if you are using Firebase services.

3. If you are not using Firebase, you do not need to change `ios/Podfile` or add a URL scheme for Google Sign-In.

---

## Apple Sign-In Status

Apple Sign-In is disabled for now.

Why:
- It requires a paid Apple Developer Program membership.
- You said the cost is too high right now.

What this means:
- The Apple button is removed from the sign-in screen.
- The app will use Google sign-in only.
- You can re-enable Apple later by restoring the Apple package, UI button, and Apple Developer setup.

---

## Backend Token Verification

### Google Token Verification (Python)

```python
from google.auth.transport import requests
from google.oauth2 import id_token

def verify_google_token(id_token_str):
    try:
        idinfo = id_token.verify_oauth2_token(id_token_str, requests.Request())
        # ID token is valid.
        userid = idinfo['sub']
        email = idinfo.get('email')
        name = idinfo.get('name')
        return {
            'userid': userid,
            'email': email,
            'name': name,
        }
    except ValueError:
        # Invalid token.
        raise Exception('Invalid Google token')
```

Installation:
```bash
pip install google-auth google-auth-oauthlib google-auth-httplib2
```

### Apple Token Verification (Python)

```python
import jwt
import json
from urllib.request import urlopen

def verify_apple_token(id_token_str):
    try:
        # Get Apple's public keys
        url = 'https://appleid.apple.com/auth/keys'
        response = urlopen(url)
        keys = json.loads(response.read())
        
        # Decode without verification first to get kid
        unverified_header = jwt.get_unverified_header(id_token_str)
        kid = unverified_header['kid']
        
        # Find matching key
        key = None
        for k in keys['keys']:
            if k['kid'] == kid:
                key = k
                break
        
        if not key:
            raise Exception('Key not found')
        
        # Verify the token
        decoded = jwt.decode(
            id_token_str,
            json.dumps(key),
            algorithms=['RS256'],
            audience='com.example.hitmeup',  # Your bundle ID
            options={'verify_aud': True}
        )
        
        return {
            'userid': decoded['sub'],
            'email': decoded.get('email'),
        }
    except Exception as e:
        raise Exception(f'Invalid Apple token: {str(e)}')
```

Installation:
```bash
pip install PyJWT cryptography
```

---

## Testing Locally

### Android Testing

1. Run on Android device/emulator:
```bash
flutter run
```

2. Tap Google icon - should show account picker
3. Apple sign-in is disabled in the current build

### iOS Testing

1. Must use physical iOS device (simulator doesn't support native auth)
2. Configure signing in Xcode:
   - Select Runner project
   - Build Settings → Code Signing Identity
   - Select your team

3. Run:
```bash
flutter run -d <device_udid>
```

---

## Common Issues

### "No activities found"
- Ensure `google-services.json` is in `android/app/`
- Run: `flutter clean && flutter pub get`

### "GooglePlayServicesNotAvailableException"
- Ensure Google Play Services are installed on Android device

### "Invalid SHA-1 certificate"
- Regenerate SHA-1 fingerprint and update Google Cloud Console
- Different signing keys for debug vs release!

### Apple Sign-In not showing on Android
- Normal behavior (Apple only supports iOS)
- Can add Apple backend authentication for web

### "Service ID not configured"
- Ensure Service ID is created in Apple Developer Account
- Add domain verification

### "Apple sign-in missing"
- This is expected for the current build
- Apple sign-in is intentionally disabled until you have an Apple Developer Program account

---

## Release/Production Setup

### Android Release Build

1. Create keystore:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 4096 -validity 10950 \
  -alias upload
```

2. Update `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

3. Update `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### iOS Release Build

1. In Xcode:
   - Select Runner → Build Settings
   - Code Signing Identity: Select your team
   - Provisioning Profile: Select matching profile

2. Export for distribution:
   - Product → Archive
   - Distribute App

---

## Documentation Links

- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [Sign in with Apple Flutter](https://pub.dev/packages/sign_in_with_apple)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Apple Developer Account](https://developer.apple.com/account/)
