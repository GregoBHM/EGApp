import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/home/screens/home_screen.dart';
import 'features/guias/screens/emitir_guia_screen.dart';
import 'features/guias/screens/historial_guias_screen.dart';
import 'features/empresa/screens/configurar_sunat_screen.dart';
import 'features/empresa/screens/gestionar_choferes_screen.dart';
import 'features/empresa/screens/seleccionar_empresa_screen.dart';
import 'features/shell/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/seleccionar-empresa',
        builder: (context, state) => const SeleccionarEmpresaScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/emitir', builder: (context, state) => const EmitirGuiaScreen()),
          GoRoute(path: '/historial', builder: (context, state) => const HistorialGuiasScreen()),
          GoRoute(path: '/configurar-sunat', builder: (context, state) => const ConfigurarSunatScreen()),
          GoRoute(path: '/choferes', builder: (context, state) => const GestionarChoferesScreen()),
        ],
      ),
    ],
  );
});
