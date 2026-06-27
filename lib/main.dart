import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cc_evs/firebase_options.dart';
import 'package:flutter_cc_evs/routes/route_manager.dart';
import 'package:flutter_cc_evs/theme/app_theme.dart';
import 'package:flutter_cc_evs/viewmodels/sign_in_viewmodel.dart';
import 'package:flutter_cc_evs/viewmodels/sign_up_documents_view_model.dart';
import 'package:flutter_cc_evs/viewmodels/sign_up_employee_view_model.dart';
import 'package:flutter_cc_evs/viewmodels/sign_up_personal_view_model.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
   options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignInViewModel()),
        ChangeNotifierProvider(create: (_) => SignUpPersonalViewModel()),
        ChangeNotifierProvider(create: (_) => SignUpEmployeeViewModel()),
        ChangeNotifierProvider(create: (_) => SignUpDocumentsViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Persistent Nav Demo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: EVSAppTheme.lightTheme,
      darkTheme: EVSAppTheme.darkTheme,
      initialRoute: RouteManager.signIn,
      onGenerateRoute: RouteManager.generateRoute,
    );
  }
}
