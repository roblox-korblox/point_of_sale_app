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
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    context.read<TransactionBloc>().add(
      LoadTransactionsByDateRangeEvent(
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  Future<void> _exportToPdf() async {
    if (!mounted) return;

    final chartState = context.read<ChartBloc>().state;
    final transactionState = context.read<TransactionBloc>().state;

    if (chartState is! ChartLoaded || transactionState is! TransactionLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There is no data to export'),
          backgroundColor: AppColors.error,
        ),
      );
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
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return SingleChildScrollView(
      padding: Responsive.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSizes.paddingS,
            children: [
              _buildPeriodButton(context, 'today', AppStrings.today),
              _buildPeriodButton(context, 'week', AppStrings.thisWeek),
              _buildPeriodButton(context, 'month', AppStrings.thisMonth),
              _buildPeriodButton(context, 'year', AppStrings.thisYear),
            ],
          ),
          const SizedBox(height: AppSizes.paddingL),
          CustomButton(
            text: AppStrings.exportPdf,
            onPressed: _exportToPdf,
            icon: Icons.picture_as_pdf,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(BuildContext context, String period, String label) {
    final isSelected = _selectedPeriod == period;

    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedPeriod = period);
        _loadData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF2563EB) : Colors.white,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF2563EB),
        side: const BorderSide(color: Color(0xFF2563EB)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(label),
    );
  }
}