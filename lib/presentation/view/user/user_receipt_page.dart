import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/printer_service.dart';
import '../../bloc/history/history_bloc.dart';
import '../../bloc/history/history_event.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import 'printer_scan_page.dart';

class UserReceiptPage extends StatefulWidget {
  final OrderModel order;

  const UserReceiptPage({super.key, required this.order});

  @override
  State<UserReceiptPage> createState() => _UserReceiptPageState();
}

class _UserReceiptPageState extends State<UserReceiptPage> {
  bool _isPrinting = false;
  final PrinterService _printerService = PrinterService();

  Future<void> _printReceipt() async {
    if (!mounted) return;

    setState(() {
      _isPrinting = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      // Generate PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, double.infinity),
          margin: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  AppStrings.appName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'STRUK PEMBAYARAN',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [pw.Text('ID Pesanan'), pw.Text(widget.order.id)],
                  ),
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tanggal'),
                    pw.Text(
                      DateFormatter.formatDateTimeForReceipt(
                        widget.order.createdAt,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Metode'),
                    pw.Text(widget.order.paymentMethod.toUpperCase()),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  color: PdfColors.grey300,
                  height: 1,
                ),
                pw.SizedBox(height: 6),

                // Items
                ...widget.order.items.map(
                  (item) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              item.product.name,
                              style: pw.TextStyle(fontSize: 11),
                            ),
                          ),
                          pw.Text(
                            'x${item.quantity}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            CurrencyFormatter.format(item.finalPrice),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            CurrencyFormatter.format(item.total),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  color: PdfColors.grey300,
                  height: 1,
                ),
                pw.SizedBox(height: 6),

                // Total Section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Subtotal',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      CurrencyFormatter.format(widget.order.subtotal),
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                if (widget.order.totalDiscount > 0) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Diskon',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        CurrencyFormatter.format(widget.order.totalDiscount),
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
                pw.SizedBox(height: 6),
                pw.Container(
                  width: double.infinity,
                  color: PdfColors.grey300,
                  height: 1,
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      CurrencyFormatter.format(widget.order.total),
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // Footer
                pw.Text(
                  'Terima Kasih!',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Selamat Berbelanja Kembali',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '--- ${AppStrings.appName} ---',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ],
            );
          },
        ),
      );

      // Print PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Struk berhasil di-print (PDF)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  Future<void> _printToBluetoothPrinter() async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    if (!_printerService.isConnected) {
      // Show dialog to select printer
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PrinterScanPage()),
      );

      if (!mounted) return;

      if (!_printerService.isConnected) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Printer tidak terhubung. Silakan pilih printer terlebih dahulu.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      await _printerService.printReceipt(widget.order);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Struk berhasil di-print ke printer Bluetooth'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.receipt),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Receipt Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingL),
                  child: Column(
                    children: [
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeXXL,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingS),
                      const Text(
                        'Struk Pembayaran',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeL,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: AppSizes.paddingS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ID Pesanan:'),
                          Text(widget.order.id),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tanggal:'),
                          Text(
                            DateFormatter.formatDateTimeForReceipt(
                              widget.order.createdAt,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Metode:'),
                          Text(widget.order.paymentMethod.toUpperCase()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),
              // Items
              const Text(
                'Items:',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeXL,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),
              ...widget.order.items.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
                  child: ListTile(
                    title: Text(item.product.name),
                    subtitle: Text('${AppStrings.quantity}: ${item.quantity}'),
                    trailing: Text(
                      CurrencyFormatter.format(item.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),
              // Total
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:'),
                          Text(CurrencyFormatter.format(widget.order.subtotal)),
                        ],
                      ),
                      if (widget.order.totalDiscount > 0) ...[
                        const SizedBox(height: AppSizes.paddingS),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Diskon:'),
                            Text(
                              CurrencyFormatter.format(
                                widget.order.totalDiscount,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            AppStrings.total,
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeXL,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(widget.order.total),
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeXL,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),
              // Print Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'PDF',
                      onPressed: _isPrinting ? null : _printReceipt,
                      isLoading: _isPrinting,
                      icon: Icons.picture_as_pdf,
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingS),
                  Expanded(
                    child: CustomButton(
                      text: 'Printer',
                      onPressed: _isPrinting ? null : _printToBluetoothPrinter,
                      isLoading: _isPrinting,
                      icon: Icons.print,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingS),
              // Bluetooth Printer Status and Settings
              if (_printerService.isConnected)
                Card(
                  color: AppColors.success.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingS),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bluetooth_connected,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.paddingS),
                        Expanded(
                          child: Text(
                            'Terhubung: ${_printerService.connectedDevice?.name ?? "Unknown"}',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeS,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrinterScanPage(),
                              ),
                            ).then((_) {
                              if (mounted) {
                                setState(() {});
                              }
                            });
                          },
                          child: const Text('Ganti'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingS),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.paddingS),
                        Expanded(
                          child: Text(
                            'Printer Bluetooth belum terhubung',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeS,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrinterScanPage(),
                              ),
                            ).then((_) {
                              if (mounted) {
                                setState(() {});
                              }
                            });
                          },
                          child: const Text('Pilih Printer'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSizes.paddingM),
              // Done Button
              CustomButton(
                text: 'Selesai',
                onPressed: () async {
                  if (!mounted) return;
                  
                  // Get NavigatorState before async operation
                  final navigator = Navigator.of(context);
                  
                  // Refresh history before navigating back
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    context.read<HistoryBloc>().add(
                      LoadHistoryEvent(userId: authState.user.id),
                    );
                  }
                  
                  // Save flag to indicate order was completed
                  // This will be used to switch to history tab in UserHistoryPage
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('show_history_after_order', true);
                  
                  // Navigate back to the first route (UserHistoryPage)
                  // Check mounted again after async operation
                  if (mounted) {
                    navigator.popUntil((route) => route.isFirst);
                  }
                },
                icon: Icons.check_circle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
