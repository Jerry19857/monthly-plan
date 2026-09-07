import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/db/app_database.dart';
import 'core/sheet_api.dart';
import 'features/auth/auth_cubit.dart';
import 'features/auth/pin_screen.dart';
import 'features/monthly_plan/monthly_plan_cubit.dart';
import 'home_shell.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final api = SheetApi();
  runApp(App(db: db, api: api));
}

class App extends StatelessWidget {
  const App({super.key, required this.db, required this.api});

  final AppDatabase db;
  final SheetApi api;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: db),
        RepositoryProvider.value(value: api),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(api)),
        ],
        child: Builder(builder: (context) {
          return BlocProvider(
            create: (_) =>
                MonthlyPlanCubit(db, api, context.read<AuthCubit>()),
            child: MaterialApp(
              title: 'วางแผนการเงิน',
              debugShowCheckedModeBanner: false,
              theme: buildMaterialTheme(),
              locale: const Locale('th'),
              supportedLocales: const [Locale('th'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const _Root(),
            ),
          );
        }),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.unlocked) return const HomeShell();
        if (state.status == AuthStatus.unknown) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return const PinScreen();
      },
    );
  }
}
