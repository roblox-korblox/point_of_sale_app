import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../core/constants/strings.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthEvent>(_onCheckAuth);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _authService.login(event.username, event.password);
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_id', user.id);
        await prefs.setBool('is_logged_in', true);
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError(AppStrings.invalidCredentials));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _authService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      await prefs.setBool('is_logged_in', false);
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCheckAuth(CheckAuthEvent event, Emitter<AuthState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final userId = prefs.getString('current_user_id');

      if (isLoggedIn && userId != null) {
        try {
          final users = _authService.dummyUsers;
          final user = users.firstWhere(
            (u) => u.id == userId,
            orElse: () => throw Exception('User not found'),
          );
          emit(AuthAuthenticated(user));
        } catch (e) {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }
}

