import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/empty_widget.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/chart/chart_bloc.dart';
import '../../bloc/chart/chart_event.dart';
import '../../bloc/chart/chart_state.dart';
import 'admin_product_page_content.dart';
import 'admin_report_page_content.dart';
import 'admin_history_page_content.dart';
import 'admin_product_form_page.dart';
import '../../bloc/history/history_bloc.dart';
import '../../bloc/history/history_event.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../../data/services/transaction_service.dart';
import '../../../data/models/product_model.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String _selectedPeriod = 'today';
  final TransactionService _transactionService = TransactionService();
  List<Map<String, dynamic>> _soldProductsToday = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<ChartBloc>().add(LoadChartDataEvent(_selectedPeriod));
    _loadSoldProductsToday();
    // Also load history initially
    context.read<HistoryBloc>().add(const LoadHistoryEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Note: We don't use didChangeDependencies here because it's called too frequently
  // Instead, we refresh data when:
  // 1. User switches to dashboard tab (in onTap)
  // 2. App comes to foreground (in didChangeAppLifecycleState)
  // 3. User manually refreshes (via refresh button)
  // 4. Period changes (in _onPeriodChanged)

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app comes to foreground, refresh dashboard data
    if (state == AppLifecycleState.resumed && _selectedIndex == 0) {
      _refreshDashboardData();
    }
  }

  void _refreshDashboardData() {
    if (!mounted) return;
    context.read<ChartBloc>().add(LoadChartDataEvent(_selectedPeriod));
    if (_selectedPeriod == 'today') {
      _loadSoldProductsToday();
    }
    // Also refresh history
    context.read<HistoryBloc>().add(const LoadHistoryEvent());
  }

  Future<void> _loadSoldProductsToday() async {
    final products = await _transactionService.getSoldProductsToday();
    if (mounted) {
      setState(() {
        _soldProductsToday = products;
      });
    }
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    context.read<ChartBloc>().add(LoadChartDataEvent(period));
    if (period == 'today') {
      _loadSoldProductsToday();
    } else {
      setState(() {
        _soldProductsToday = [];
      });
    }
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return AppStrings.dashboard;
      case 1:
        return AppStrings.products;
      case 2:
        return AppStrings.orderHistory;
      case 3:
        return AppStrings.report;
      default:
        return AppStrings.dashboard;
    }
  }

  List<Widget> _getAppBarActions() {
    return [
      if (_selectedIndex == 0)
        // Dashboard tab: Show refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            _refreshDashboardData();
          },
          tooltip: 'Refresh Dashboard',
        ),
      if (_selectedIndex == 2)
        // History tab: Show refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<HistoryBloc>().add(const LoadHistoryEvent());
          },
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
          _buildDashboardTab(),
          const AdminProductPageContent(),
          const AdminHistoryPageContent(),
          const AdminReportPageContent(),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? Builder(
              builder: (context) {
                final productBloc = context.read<ProductBloc>();
                return FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminProductFormPage(),
                      ),
                    ).then((_) {
                      if (mounted) {
                        productBloc.add(const LoadProductsEvent());
                      }
                    });
                  },
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.add, color: AppColors.textWhite),
                );
              },
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          final productBloc = context.read<ProductBloc>();
          final historyBloc = context.read<HistoryBloc>();
          
          setState(() {
            _selectedIndex = index;
          });
          
          if (index == 0) {
            // Dashboard tab: Refresh all dashboard data
            _refreshDashboardData();
          } else if (index == 1) {
            // Products tab: Load products
            if (mounted) {
              productBloc.add(const LoadProductsEvent());
            }
          } else if (index == 2) {
            // History tab: Load history
            if (mounted) {
              historyBloc.add(const LoadHistoryEvent());
            }
          } else if (index == 3) {
            // Report page will load data in initState
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: AppStrings.dashboard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: AppStrings.products,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: AppStrings.history,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: AppStrings.report,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobile(context);
        final isTablet = Responsive.isTablet(context);
        
        return SingleChildScrollView(
          padding: Responsive.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector - Responsive
              if (isMobile)
                // Mobile: Use Wrap or Grid
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSizes.paddingS,
                  runSpacing: AppSizes.paddingS,
                  children: [
                    _buildPeriodButton(context, 'today', AppStrings.today),
                    _buildPeriodButton(context, 'week', AppStrings.thisWeek),
                    _buildPeriodButton(context, 'month', AppStrings.thisMonth),
                    _buildPeriodButton(context, 'year', AppStrings.thisYear),
                  ],
                )
              else
                // Tablet/Desktop: Use Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildPeriodButton(context, 'today', AppStrings.today)),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(child: _buildPeriodButton(context, 'week', AppStrings.thisWeek)),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(child: _buildPeriodButton(context, 'month', AppStrings.thisMonth)),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(child: _buildPeriodButton(context, 'year', AppStrings.thisYear)),
                  ],
                ),
              const SizedBox(height: AppSizes.paddingL),
              // Sold Products Today
              if (_selectedPeriod == 'today') ...[
                const Text(
                  AppStrings.soldProducts,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeXL,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingM),
                _buildSoldProductsList(),
                const SizedBox(height: AppSizes.paddingL),
              ],
              // Chart Data - Responsive Grid
              BlocBuilder<ChartBloc, ChartState>(
                builder: (context, state) {
                  if (state is ChartLoading) {
                    return const LoadingWidget();
                  } else if (state is ChartLoaded) {
                    if (isMobile) {
                      // Mobile: Single column
                      return Column(
                        children: [
                          _buildStatCard(
                            context,
                            AppStrings.income,
                            CurrencyFormatter.format(state.income),
                            AppColors.chartIncome,
                            Icons.trending_up,
                          ),
                          const SizedBox(height: AppSizes.paddingM),
                          _buildStatCard(
                            context,
                            AppStrings.expense,
                            CurrencyFormatter.format(state.expense),
                            AppColors.chartExpense,
                            Icons.trending_down,
                          ),
                          const SizedBox(height: AppSizes.paddingM),
                          _buildStatCard(
                            context,
                            AppStrings.profit,
                            CurrencyFormatter.format(state.profit),
                            AppColors.chartProfit,
                            Icons.arrow_upward,
                          ),
                          const SizedBox(height: AppSizes.paddingM),
                          _buildStatCard(
                            context,
                            AppStrings.loss,
                            CurrencyFormatter.format(state.loss),
                            AppColors.chartLoss,
                            Icons.arrow_downward,
                          ),
                        ],
                      );
                    } else {
                      // Tablet/Desktop: Grid layout
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isTablet ? 2 : 4,
                        crossAxisSpacing: AppSizes.paddingM,
                        mainAxisSpacing: AppSizes.paddingM,
                        childAspectRatio: isTablet ? 1.5 : 1.2,
                        children: [
                          _buildStatCard(
                            context,
                            AppStrings.income,
                            CurrencyFormatter.format(state.income),
                            AppColors.chartIncome,
                            Icons.trending_up,
                          ),
                          _buildStatCard(
                            context,
                            AppStrings.expense,
                            CurrencyFormatter.format(state.expense),
                            AppColors.chartExpense,
                            Icons.trending_down,
                          ),
                          _buildStatCard(
                            context,
                            AppStrings.profit,
                            CurrencyFormatter.format(state.profit),
                            AppColors.chartProfit,
                            Icons.arrow_upward,
                          ),
                          _buildStatCard(
                            context,
                            AppStrings.loss,
                            CurrencyFormatter.format(state.loss),
                            AppColors.chartLoss,
                            Icons.arrow_downward,
                          ),
                        ],
                      );
                    }
                  } else if (state is ChartError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    );
                  } else {
                    return const EmptyWidget(message: AppStrings.noData);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodButton(BuildContext context, String period, String label) {
    final isSelected = _selectedPeriod == period;
    final isMobile = Responsive.isMobile(context);
    
    return SizedBox(
      width: isMobile ? null : double.infinity,
      child: ElevatedButton(
        onPressed: () => _onPeriodChanged(period),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
          foregroundColor: isSelected ? AppColors.textWhite : AppColors.textPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSizes.paddingS : AppSizes.paddingM,
            vertical: AppSizes.paddingS,
          ),
          minimumSize: Size(isMobile ? 0 : double.infinity, AppSizes.buttonHeightM),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.getResponsiveFontSize(
                context,
                mobile: AppSizes.fontSizeS,
                tablet: AppSizes.fontSizeM,
                desktop: AppSizes.fontSizeL,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(
          isMobile ? AppSizes.paddingM : AppSizes.paddingL,
        ),
        child: isMobile || isTablet
            ? Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      isMobile ? AppSizes.paddingS : AppSizes.paddingM,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: isMobile ? 24 : 32,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveFontSize(
                              context,
                              mobile: AppSizes.fontSizeS,
                              tablet: AppSizes.fontSizeM,
                            ),
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingXS),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveFontSize(
                                context,
                                mobile: AppSizes.fontSizeL,
                                tablet: AppSizes.fontSizeXL,
                                desktop: 24,
                              ),
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingL),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                    child: Icon(icon, color: color, size: 48),
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeM,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.paddingS),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSoldProductsList() {
    if (_soldProductsToday.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.paddingL),
          child: Center(
            child: Text('Tidak ada produk terjual hari ini'),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Produk Terjual Hari Ini',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeL,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadSoldProductsToday,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _soldProductsToday.length,
            itemBuilder: (context, index) {
              final item = _soldProductsToday[index];
              final product = item['product'] as ProductModel;
              final quantity = item['quantity'] as int;
              final total = item['total'] as int;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL,
                  vertical: AppSizes.paddingS,
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('Jumlah: $quantity'),
                trailing: Text(
                  CurrencyFormatter.format(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

