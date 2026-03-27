import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const HitMeUpApp());
}

class HitMeUpApp extends StatelessWidget {
  const HitMeUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HitMeUp',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Keep layout static when the keyboard opens.
        return MediaQuery(
          data: mediaQuery.copyWith(viewInsets: EdgeInsets.zero),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
