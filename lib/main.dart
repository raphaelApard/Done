import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';
import 'store.dart';
import 'theme.dart';
import 'todo_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  final store = await TodoStore.load();
  runApp(DoneApp(store: store));
}

class DoneApp extends StatelessWidget {
  const DoneApp({super.key, required this.store, this.webFonts = true});

  final TodoStore store;

  /// Set to false to use the platform font (tests run without network).
  final bool webFonts;

  /// Widest the UI grows on tablets, desktop and the web.
  static const maxContentWidth = 520.0;

  @override
  Widget build(BuildContext context) {
    return TodoScope(
      store: store,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => MaterialApp(
          title: 'Done',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light, webFonts: webFonts),
          darkTheme: buildTheme(Brightness.dark, webFonts: webFonts),
          themeMode: store.themeMode,
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: child,
              ),
            ),
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
