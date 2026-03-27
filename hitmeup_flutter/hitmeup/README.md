# HitMeUp Flutter App

Social connection app (Tinder/Bumble style) — Sign In & Sign Up flow.

## Project Structure

```
lib/
├── main.dart                          # Entry point
├── theme/
│   └── app_theme.dart                 # Colors, gradients, text styles
├── widgets/
│   └── common_widgets.dart            # Shared widgets (buttons, fields, chips, etc.)
└── screens/
    ├── splash_screen.dart             # App logo / splash
    ├── auth/
    │   └── sign_in_screen.dart        # Sign In page
    ├── signup/
    │   ├── step1_intro_screen.dart    # Step 1 — Name, Email, Password
    │   ├── step2_gender_screen.dart   # Step 2 — Your Gender
    │   ├── step3_birthday_screen.dart # Step 3 — Birthday (CupertinoDatePicker)
    │   ├── step4_location_screen.dart # Step 4 — Where do you live (dropdown)
    │   ├── step5_meet_gender_screen.dart # Step 5 — Who do you want to meet
    │   └── step6_interests_screen.dart   # Step 6 — Pick your interests
    └── home/
        └── home_screen.dart           # Home screen placeholder
```

## Setup

1. **Add your logo** — Put `hitmeup.jpg` in `assets/` folder (create it if needed)

2. **pubspec.yaml** — Already configured for the asset. Run:
   ```bash
   flutter pub get
   ```

3. **(Optional) Add Nunito font** — Download from [Google Fonts](https://fonts.google.com/specimen/Nunito), put in `fonts/`, then uncomment the font section in `pubspec.yaml`.

4. **Run the app:**
   ```bash
   flutter run
   ```

## Navigation Flow

```
SplashScreen → (tap logo)
  → SignInScreen → (Sign Up button)
    → Step1IntroScreen
      → Step2GenderScreen
        → Step3BirthdayScreen
          → Step4LocationScreen
            → Step5MeetGenderScreen
              → Step6InterestsScreen
                → HomeScreen
```

## Backend Integration (Django)

When ready to connect to backend:

- **Sign In**: POST `/api/auth/login/` with `{ username, password }`
- **Sign Up**: POST `/api/auth/register/` with `{ name, email, password, gender, birthday, location, meet_gender, interests[] }`
- Use `http` or `dio` package for API calls
- Store JWT token in `flutter_secure_storage`

## Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Pink | `#FF4081` | Top gradient, accent |
| Mint | `#E0F2F1` | Mid gradient |
| Blue | `#448AFF` | Bottom gradient, step indicator |
| White | `#FFFFFF` | Cards, buttons |
