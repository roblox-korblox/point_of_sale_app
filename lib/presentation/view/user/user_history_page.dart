import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/empty_widget.dart';
import '../../../data/models/order_model.dart';
import '../../bloc/history/history_bloc.dart';
import '../../bloc/history/history_event.dart';
import '../../bloc/history/history_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/order/order_bloc.dart';
import '../../bloc/order/order_event.dart';
import '../../bloc/order/order_state.dart';
import 'user_history_detail_page.dart';
import 'user_product_page_content.dart';
import 'user_cart_page_content.dart';

class UserHistoryPage extends StatefulWidget {
  const UserHistoryPage({super.key});

  @override
  State<UserHistoryPage> createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends State<UserHistoryPage> with WidgetsBindingObserver {
  int _selectedIndex = 0; // Start with products tab
  bool _hasCheckedHistoryFlag = false; // Track if we've checked the flag

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductBloc>().add(const LoadProductsEvent());
        context.read<OrderBloc>().add(const LoadCurrentCartEvent());
        // Also load history initially
        _loadHistory();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check flag when dependencies change (e.g., after returning from receipt page)
    // This ensures we switch to history tab if order was just completed
    if (!_hasCheckedHistoryFlag) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndSwitchToHistoryTab();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app comes to foreground, reset flag check to allow checking again
    if (state == AppLifecycleState.resumed) {
      _hasCheckedHistoryFlag = false;
    }
  }

  Future<void> _checkAndSwitchToHistoryTab() async {
    if (!mounted || _hasCheckedHistoryFlag) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final showHistory = prefs.getBool('show_history_after_order') ?? false;
      if (showHistory) {
        // Clear the flag immediately to prevent duplicate checks
        await prefs.setBool('show_history_after_order', false);
        // Switch to history tab
        if (mounted) {
          setState(() {
            _selectedIndex = 1; // Switch to history tab
          });
          // Refresh history to show the new order
          _loadHistory();
        }
      }
      // Mark as checked after processing (whether flag was set or not)
      _hasCheckedHistoryFlag = true;
    } catch (e) {
      // Handle error silently
      _hasCheckedHistoryFlag = true;
    }
  }

  void _loadHistory() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<HistoryBloc>().add(
        LoadHistoryEvent(userId: authState.user.id),
      );
    }
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return AppStrings.appName;
      case 1:
        return AppStrings.orderHistory;
      case 2:
        return AppStrings.cart;
      default:
        return AppStrings.appName;
    }
  }

  List<Widget> _getAppBarActions() {
    switch (_selectedIndex) {
      case 0:
        // Products tab - show cart icon and logout
        return [
          BlocBuilder<OrderBloc, OrderState>(
            builder: (context, orderState) {
              final cartItemCount = orderState is CartLoaded ? orderState.cartItems.length : 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 2; // Switch to cart tab
                      });
                      if (mounted) {
                        context.read<OrderBloc>().add(const LoadCurrentCartEvent());
                      }
                    },
                    tooltip: AppStrings.cart,
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$cartItemCount',
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutEvent());
            },
            tooltip: 'Logout',
          ),
        ];
      case 1:
        // History tab - show refresh and logout
        return [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutEvent());
            },
            tooltip: 'Logout',
          ),
        ];
      case 2:
        // Cart tab - show logout only
        return [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutEvent());
            },
            tooltip: 'Logout',
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: _getAppBarActions(),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const UserProductPageContent(),
          _buildHistoryTab(),
          const UserCartPageContent(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          final productBloc = context.read<ProductBloc>();
          final orderBloc = context.read<OrderBloc>();
          
          setState(() {
            _selectedIndex = index;
          });
          
          if (index == 0) {
            // Load products and cart when switching to products tab
            if (mounted) {
              productBloc.add(const LoadProductsEvent());
              orderBloc.add(const LoadCurrentCartEvent());
            }
          } else if (index == 1) {
            _loadHistory();
          } else if (index == 2) {
            // Load cart when switching to cart tab
            if (mounted) {
              orderBloc.add(const LoadCurrentCartEvent());
            }
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: AppStrings.history,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: AppStrings.cart,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading) {
          return const LoadingWidget();
        } else if (state is HistoryLoaded) {
          if (state.orders.isEmpty) {
            return const EmptyWidget(
              message: 'Tidak ada riwayat pesanan',
              icon: Icons.history,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadHistory();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return _buildOrderCard(context, order);
              },
            ),
          );
        } else if (state is HistoryError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: AppSizes.paddingM),
                ElevatedButton(
                  onPressed: _loadHistory,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        } else {
          return const EmptyWidget(message: AppStrings.noData);
        }
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserHistoryDetailPage(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'ID: ${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppSizes.fontSizeM,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingS,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: order.status == 'completed'
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: order.status == 'completed'
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: AppSizes.fontSizeS,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingS),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatDateTime(order.createdAt),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontSizeS,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingS),
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontSizeS,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    order.paymentMethod == 'cash' ? Icons.money : Icons.qr_code,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.paymentMethod.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontSizeS,
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSizes.paddingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeM,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(order.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.fontSizeXL,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
