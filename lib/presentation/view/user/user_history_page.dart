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

class _UserHistoryPageState extends State<UserHistoryPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _hasCheckedHistoryFlag = false;

  static const Color _bgColor = Color(0xFFF3F6F2);
  static const Color _softGreen = Color(0xFFE4F0E6);
  static const Color _primaryGreen = Color(0xFF2E9E4D);
  static const Color _darkText = Color(0xFF1D1D1F);
  static const Color _softText = Color(0xFF6E6E73);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductBloc>().add(const LoadProductsEvent());
        context.read<OrderBloc>().add(const LoadCurrentCartEvent());
        _loadHistory();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
        await prefs.setBool('show_history_after_order', false);

        if (mounted) {
          setState(() {
            _selectedIndex = 1;
          });
          _loadHistory();
        }
      }

      _hasCheckedHistoryFlag = true;
    } catch (e) {
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
        return [
          BlocBuilder<OrderBloc, OrderState>(
            builder: (context, orderState) {
              final cartItemCount =
                  orderState is CartLoaded ? orderState.cartItems.length : 0;

              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Stack(
                  children: [
                    _buildCircleIconButton(
                      icon: Icons.shopping_cart_outlined,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 2;
                        });
                        if (mounted) {
                          context
                              .read<OrderBloc>()
                              .add(const LoadCurrentCartEvent());
                        }
                      },
                    ),
                    if (cartItemCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$cartItemCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildCircleIconButton(
              icon: Icons.logout_rounded,
              onTap: () {
                context.read<AuthBloc>().add(const LogoutEvent());
              },
            ),
          ),
        ];
      case 1:
        return [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _buildCircleIconButton(
              icon: Icons.refresh_rounded,
              onTap: _loadHistory,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildCircleIconButton(
              icon: Icons.logout_rounded,
              onTap: () {
                context.read<AuthBloc>().add(const LogoutEvent());
              },
            ),
          ),
        ];
      case 2:
        return [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildCircleIconButton(
              icon: Icons.logout_rounded,
              onTap: () {
                context.read<AuthBloc>().add(const LogoutEvent());
              },
            ),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: _darkText),
        tooltip: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _darkText,
        centerTitle: false,
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: _darkText,
          ),
        ),
        actions: _getAppBarActions(),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            const UserProductPageContent(),
            _buildHistoryTab(),
            const UserCartPageContent(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              final productBloc = context.read<ProductBloc>();
              final orderBloc = context.read<OrderBloc>();

              setState(() {
                _selectedIndex = index;
              });

              if (index == 0) {
                if (mounted) {
                  productBloc.add(const LoadProductsEvent());
                  orderBloc.add(const LoadCurrentCartEvent());
                }
              } else if (index == 1) {
                _loadHistory();
              } else if (index == 2) {
                if (mounted) {
                  orderBloc.add(const LoadCurrentCartEvent());
                }
              }
            },
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: _primaryGreen,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Produk',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded),
                label: AppStrings.history,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_rounded),
                label: AppStrings.cart,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        _buildHistoryHeroCard(),
        const SizedBox(height: 16),
        Expanded(
          child: BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state is HistoryLoading) {
                return const LoadingWidget();
              } else if (state is HistoryLoaded) {
                if (state.orders.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const EmptyWidget(
                      message: 'No order history',
                      icon: Icons.history,
                    ),
                  );
                }

                return RefreshIndicator(
                  color: _primaryGreen,
                  onRefresh: () async {
                    _loadHistory();
                  },
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: state.orders.length,
                    itemBuilder: (context, index) {
                      final order = state.orders[index];
                      return _buildOrderCard(context, order);
                    },
                  ),
                );
              } else if (state is HistoryError) {
                return Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red,
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadHistory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const EmptyWidget(message: AppStrings.noData),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Riwayat Pesanan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _darkText,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Lihat semua transaksi Anda dengan tampilan yang lebih rapi dan nyaman.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: _softText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: _primaryGreen,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final bool isCompleted = order.status.toLowerCase() == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserHistoryDetailPage(order: order),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFE8F6EC)
                          : const Color(0xFFFFEFEF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_outline_rounded
                          : Icons.access_time_rounded,
                      color: isCompleted ? _primaryGreen : Colors.redAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormatter.formatDateTime(order.createdAt),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _softText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFE8F6EC)
                          : const Color(0xFFFFEFEF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: isCompleted ? _primaryGreen : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Jumlah item',
                      value:
                          '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      icon: order.paymentMethod == 'cash'
                          ? Icons.payments_outlined
                          : Icons.qr_code_2_rounded,
                      label: 'Pembayaran',
                      value: order.paymentMethod.toUpperCase(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEDEDED)),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: _softText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.format(order.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: _primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F7F3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Lihat detail',
                    style: TextStyle(
                      color: _primaryGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _softText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _softText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _darkText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}