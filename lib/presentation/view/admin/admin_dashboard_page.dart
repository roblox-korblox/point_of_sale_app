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

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String _selectedPeriod = 'today';
  final TransactionService _transactionService = TransactionService();
  List<Map<String, dynamic>> _soldProductsToday = [];

  static const Color _bgColor = Color(0xFFF3F6F2);
  static const Color _softGreen = Color(0xFFE4F0E6);
  static const Color _primaryGreen = Color(0xFF2E9E4D);
  static const Color _darkText = Color(0xFF1D1D1F);
  static const Color _softText = Color(0xFF6E6E73);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<ChartBloc>().add(LoadChartDataEvent(_selectedPeriod));
    _loadSoldProductsToday();
    context.read<HistoryBloc>().add(const LoadHistoryEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
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
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _buildCircleIconButton(
            icon: Icons.refresh_rounded,
            onTap: _refreshDashboardData,
          ),
        ),
      if (_selectedIndex == 2)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _buildCircleIconButton(
            icon: Icons.refresh_rounded,
            onTap: () {
              context.read<HistoryBloc>().add(const LoadHistoryEvent());
            },
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
            _buildDashboardTab(),
            const AdminProductPageContent(),
            const AdminHistoryPageContent(),
            const AdminReportPageContent(),
          ],
        ),
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
                  backgroundColor: _primaryGreen,
                  elevation: 6,
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                );
              },
            )
          : null,
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
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
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
            onTap: (index) {
              final productBloc = context.read<ProductBloc>();
              final historyBloc = context.read<HistoryBloc>();

              setState(() {
                _selectedIndex = index;
              });

              if (index == 0) {
                _refreshDashboardData();
              } else if (index == 1) {
                if (mounted) {
                  productBloc.add(const LoadProductsEvent());
                }
              } else if (index == 2) {
                if (mounted) {
                  historyBloc.add(const LoadHistoryEvent());
                }
              } else if (index == 3) {
                // Report page will load data in initState
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: AppStrings.dashboard,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_rounded),
                label: AppStrings.products,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded),
                label: AppStrings.history,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assessment_rounded),
                label: AppStrings.report,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobile(context);
        final isTablet = Responsive.isTablet(context);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: Responsive.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDashboardHero(),
              const SizedBox(height: 18),

              if (isMobile)
                Wrap(
                  alignment: WrapAlignment.start,
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
                Row(
                  children: [
                    Expanded(
                        child: _buildPeriodButton(
                            context, 'today', AppStrings.today)),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(
                        child: _buildPeriodButton(
                            context, 'week', AppStrings.thisWeek)),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(
                        child: _buildPeriodButton(
                            context, 'month', AppStrings.thisMonth)),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(
                        child: _buildPeriodButton(
                            context, 'year', AppStrings.thisYear)),
                  ],
                ),

              const SizedBox(height: AppSizes.paddingL),

              if (_selectedPeriod == 'today') ...[
                const Padding(
                  padding: EdgeInsets.only(left: 2, bottom: 12),
                  child: Text(
                    AppStrings.soldProducts,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                    ),
                  ),
                ),
                _buildSoldProductsList(),
                const SizedBox(height: AppSizes.paddingL),
              ],

              BlocBuilder<ChartBloc, ChartState>(
                builder: (context, state) {
                  if (state is ChartLoading) {
                    return const LoadingWidget();
                  } else if (state is ChartLoaded) {
                    if (isMobile) {
                      return Column(
                        children: [
                          _buildStatCard(
                            context,
                            AppStrings.income,
                            CurrencyFormatter.format(state.income),
                            AppColors.chartIncome,
                            Icons.trending_up_rounded,
                          ),
                          const SizedBox(height: AppSizes.paddingM),
                          _buildStatCard(
                            context,
                            AppStrings.expense,
                            CurrencyFormatter.format(state.expense),
                            AppColors.chartExpense,
                            Icons.trending_down_rounded,
                          ),
                          const SizedBox(height: AppSizes.paddingM),
                          _buildStatCard(
                            context,
                            AppStrings.profit,
                            CurrencyFormatter.format(state.profit),
                            AppColors.chartProfit,
                            Icons.arrow_upward_rounded,
                          ),
                          const SizedBox(height: AppSizes.paddingM),
                          _buildStatCard(
                            context,
                            AppStrings.loss,
                            CurrencyFormatter.format(state.loss),
                            AppColors.chartLoss,
                            Icons.arrow_downward_rounded,
                          ),
                        ],
                      );
                    } else {
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isTablet ? 2 : 4,
                        crossAxisSpacing: AppSizes.paddingM,
                        mainAxisSpacing: AppSizes.paddingM,
                        childAspectRatio: isTablet ? 1.55 : 1.18,
                        children: [
                          _buildStatCard(
                            context,
                            AppStrings.income,
                            CurrencyFormatter.format(state.income),
                            AppColors.chartIncome,
                            Icons.trending_up_rounded,
                          ),
                          _buildStatCard(
                            context,
                            AppStrings.expense,
                            CurrencyFormatter.format(state.expense),
                            AppColors.chartExpense,
                            Icons.trending_down_rounded,
                          ),
                          _buildStatCard(
                            context,
                            AppStrings.profit,
                            CurrencyFormatter.format(state.profit),
                            AppColors.chartProfit,
                            Icons.arrow_upward_rounded,
                          ),
                          _buildStatCard(
                            context,
                            AppStrings.loss,
                            CurrencyFormatter.format(state.loss),
                            AppColors.chartLoss,
                            Icons.arrow_downward_rounded,
                          ),
                        ],
                      );
                    }
                  } else if (state is ChartError) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        state.message,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardHero() {
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
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _darkText,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Pantau penjualan, performa transaksi, dan aktivitas toko dalam satu tampilan.',
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.space_dashboard_rounded,
              size: 32,
              color: _primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(BuildContext context, String period, String label) {
    final isSelected = _selectedPeriod == period;
    final isMobile = Responsive.isMobile(context);

    return SizedBox(
      width: isMobile ? null : double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? _primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _onPeriodChanged(period),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSizes.paddingM : AppSizes.paddingM,
                vertical: 12,
              ),
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
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : _darkText,
                ),
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

    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(
          isMobile ? AppSizes.paddingM : AppSizes.paddingL,
        ),
        child: isMobile || isTablet
            ? Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      isMobile ? AppSizes.paddingM : AppSizes.paddingM,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: isMobile ? 24 : 30,
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
                            color: _softText,
                            fontWeight: FontWeight.w600,
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
                              fontWeight: FontWeight.w800,
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
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(icon, color: color, size: 42),
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeM,
                      color: _softText,
                      fontWeight: FontWeight.w600,
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
                        fontWeight: FontWeight.w800,
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
      return Container(
        width: double.infinity,
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
        child: const Padding(
          padding: EdgeInsets.all(AppSizes.paddingL),
          child: Center(
            child: Text(
              'No products sold today',
              style: TextStyle(
                color: _softText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 10, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Products Sold Today',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadSoldProductsToday,
                    tooltip: 'Refresh',
                    color: _darkText,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDEDED)),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _soldProductsToday.length,
            itemBuilder: (context, index) {
              final item = _soldProductsToday[index];
              final product = item['product'] as ProductModel;
              final quantity = item['quantity'] as int;
              final total = item['total'] as int;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: index == _soldProductsToday.length - 1
                      ? null
                      : const Border(
                          bottom: BorderSide(
                            color: Color(0xFFF0F0F0),
                            width: 1,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _softGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: _primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: _darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quantity: $quantity',
                            style: const TextStyle(
                              color: _softText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _primaryGreen,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}