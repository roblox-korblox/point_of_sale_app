import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/colors.dart';
import 'core/constants/strings.dart';
import 'data/storage/storage_service.dart';
import 'data/services/auth_service.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/bloc/product/product_bloc.dart';
import 'presentation/bloc/order/order_bloc.dart';
import 'presentation/bloc/transaction/transaction_bloc.dart';
import 'presentation/bloc/chart/chart_bloc.dart';
import 'presentation/bloc/history/history_bloc.dart';
import 'presentation/view/auth/login_page.dart';
import 'presentation/view/admin/admin_dashboard_page.dart';
import 'presentation/view/user/user_history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive
    await StorageService.init();
    
    // Initialize Hive boxes
    if (!Hive.isBoxOpen('users')) {
      await Hive.openBox('users');
    }
    if (!Hive.isBoxOpen('products')) {
      await Hive.openBox('products');
    }
    if (!Hive.isBoxOpen('orders')) {
      await Hive.openBox('orders');
    }
    if (!Hive.isBoxOpen('transactions')) {
      await Hive.openBox('transactions');
    }
    
    // Initialize dummy users
    final authService = AuthService();
    await authService.initializeDummyUsers();
  } catch (e) {
    // Handle initialization errors
    print('Error initializing storage: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(const CheckAuthEvent()),
        ),
        BlocProvider<ProductBloc>(
          create: (context) => ProductBloc(),
        ),
        BlocProvider<OrderBloc>(
          create: (context) => OrderBloc(),
        ),
        BlocProvider<TransactionBloc>(
          create: (context) => TransactionBloc(),
        ),
        BlocProvider<ChartBloc>(
          create: (context) => ChartBloc(),
        ),
        BlocProvider<HistoryBloc>(
          create: (context) => HistoryBloc(),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            error: AppColors.error,
            surface: AppColors.surface,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (state is AuthAuthenticated) {
              // Navigate based on user role
              if (state.user.role == 'admin') {
                return const AdminDashboardPage();
              } else {
                return const UserHistoryPage();
              }
            } else {
              return const LoginPage();
            }
          },
        ),
      ),
    );
  }
}
