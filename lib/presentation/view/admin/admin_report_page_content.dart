import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/empty_widget.dart';
import '../../bloc/chart/chart_bloc.dart';
import '../../bloc/chart/chart_event.dart';
import '../../bloc/chart/chart_state.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/transaction/transaction_event.dart';
import '../../bloc/transaction/transaction_state.dart';

class AdminReportPageContent extends StatefulWidget {
  const AdminReportPageContent({super.key});

  @override
  State<AdminReportPageContent> createState() => _AdminReportPageContentState();
}

class _AdminReportPageContentState extends State<AdminReportPageContent> {
  String _selectedPeriod = 'today';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _loadData() {
    if (!mounted) return;
    context.read<ChartBloc>().add(LoadChartDataEvent(_selectedPeriod));
    _loadTransactions();
  }

  void _loadTransactions() {
    if (!mounted) return;
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedPeriod) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          0,
          0,
          0,
        );
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1, 0, 0, 0);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    }

    context.read<TransactionBloc>().add(
      LoadTransactionsByDateRangeEvent(startDate: startDate, endDate: endDate),
    );
  }

  Future<void> _exportToPdf() async {
    if (!mounted) return;
    final chartState = context.read<ChartBloc>().state;
    final transactionState = context.read<TransactionBloc>().state;

    if (chartState is! ChartLoaded || transactionState is! TransactionLoaded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data untuk di-export'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                AppStrings.financialReport,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Periode: ${_getPeriodLabel(_selectedPeriod)}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              'Tanggal: ${DateFormatter.formatDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Item',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Jumlah',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(AppStrings.income),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        CurrencyFormatter.format(chartState.income),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(AppStrings.expense),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        CurrencyFormatter.format(chartState.expense),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(AppStrings.profit),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        CurrencyFormatter.format(chartState.profit),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(AppStrings.loss),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        CurrencyFormatter.format(chartState.loss),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Detail Transaksi')),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'ID',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Tanggal',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                ...transactionState.transactions.map(
                  (transaction) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(transaction.id),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          DateFormatter.formatDateTime(transaction.createdAt),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          CurrencyFormatter.format(transaction.income),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'today':
        return AppStrings.today;
      case 'week':
        return AppStrings.thisWeek;
      case 'month':
        return AppStrings.thisMonth;
      case 'year':
        return AppStrings.thisYear;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobile(context);
        final isTablet = Responsive.isTablet(context);

        return SingleChildScrollView(
          padding: Responsive.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Selector - Responsive
              if (isMobile)
                // Mobile: Use Wrap
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSizes.paddingS,
                  runSpacing: AppSizes.paddingS,
                  children: [
                    _buildPeriodButton(context, 'today', AppStrings.today),
                    _buildPeriodButton(context, 'week', AppStrings.thisWeek),
                    _buildPeriodButton(
                      context,
                      'month',
                      AppStrings.thisMonth,
                    ),
                    _buildPeriodButton(context, 'year', AppStrings.thisYear),
                  ],
                )
              else
                // Tablet/Desktop: Use Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildPeriodButton(
                        context,
                        'today',
                        AppStrings.today,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(
                      child: _buildPeriodButton(
                        context,
                        'week',
                        AppStrings.thisWeek,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(
                      child: _buildPeriodButton(
                        context,
                        'month',
                        AppStrings.thisMonth,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(
                      child: _buildPeriodButton(
                        context,
                        'year',
                        AppStrings.thisYear,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppSizes.paddingL),
              // Chart Data - Responsive
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
                          ),
                          const SizedBox(height: AppSizes.paddingM),
                          _buildStatCard(
                            context,
                            AppStrings.expense,
                            CurrencyFormatter.format(state.expense),
                            AppColors.chartExpense,
                          ),
                          const SizedBox(height: AppSizes.paddingM),
                          _buildStatCard(
                            context,
                            AppStrings.profit,
                            CurrencyFormatter.format(state.profit),
                            AppColors.chartProfit,
                          ),
                          const SizedBox(height: AppSizes.paddingM),
                          _buildStatCard(
                            context,
                            AppStrings.loss,
                            CurrencyFormatter.format(state.loss),
                            AppColors.chartLoss,
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
                          ),
                          _buildStatCard(
                            context,
                            AppStrings.expense,
                            CurrencyFormatter.format(state.expense),
                            AppColors.chartExpense,
                          ),
                          _buildStatCard(
                            context,
                            AppStrings.profit,
                            CurrencyFormatter.format(state.profit),
                            AppColors.chartProfit,
                          ),
                          _buildStatCard(
                            context,
                            AppStrings.loss,
                            CurrencyFormatter.format(state.loss),
                            AppColors.chartLoss,
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
              const SizedBox(height: AppSizes.paddingL),
              // Transactions List
              BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  if (state is TransactionLoading) {
                    return const LoadingWidget();
                  } else if (state is TransactionLoaded) {
                    if (state.transactions.isEmpty) {
                      return const EmptyWidget(message: AppStrings.noData);
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Transaksi',
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveFontSize(
                              context,
                              mobile: AppSizes.fontSizeL,
                              tablet: AppSizes.fontSizeXL,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        ...state.transactions.map(
                          (transaction) => Card(
                            margin: const EdgeInsets.only(
                              bottom: AppSizes.paddingS,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(AppSizes.paddingM),
                              title: Text(
                                'ID: ${transaction.id}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                DateFormatter.formatDateTime(
                                  transaction.createdAt,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    CurrencyFormatter.format(
                                      transaction.income,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ),
                              isThreeLine: false,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else if (state is TransactionError) {
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
              const SizedBox(height: AppSizes.paddingL),
              // Export PDF Button
              CustomButton(
                text: AppStrings.exportPdf,
                onPressed: _exportToPdf,
                icon: Icons.picture_as_pdf,
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
        onPressed: () {
          setState(() {
            _selectedPeriod = period;
          });
          _loadData();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
          foregroundColor: isSelected
              ? AppColors.textWhite
              : AppColors.textPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSizes.paddingS : AppSizes.paddingM,
            vertical: AppSizes.paddingS,
          ),
          minimumSize: Size(
            isMobile ? 0 : double.infinity,
            AppSizes.buttonHeightM,
          ),
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
  ) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isMobile ? AppSizes.paddingM : AppSizes.paddingL,
        ),
        child: isMobile || isTablet
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveFontSize(
                          context,
                          mobile: AppSizes.fontSizeM,
                          tablet: AppSizes.fontSizeL,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingS),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: AppSizes.fontSizeL,
                            tablet: AppSizes.fontSizeXL,
                            desktop: 20,
                          ),
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        mobile: AppSizes.fontSizeM,
                        tablet: AppSizes.fontSizeL,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.paddingM),
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
}

