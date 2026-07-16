import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/rust/frb_generated.dart';
import 'features/welcome/welcome_screen.dart';
import 'features/theme/theme_state.dart';
import 'features/editor/rpl_languages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  registerRplLanguages();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const RplStudioApp(),
    ),
  );
}

class RplStudioApp extends StatelessWidget {
  const RplStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'RPL Studio',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: const WelcomeScreen(),
    );
  }
}
