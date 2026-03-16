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

  /// ---------------- PRINT PDF ----------------
  Future<void> _printReceipt() async {
    if (!mounted) return;

    setState(() => _isPrinting = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
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
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 8),

                ...widget.order.items.map(
                  (item) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("${item.product.name} x${item.quantity}"),
                      pw.Text(CurrencyFormatter.format(item.total)),
                    ],
                  ),
                ),

                pw.SizedBox(height: 8),

                pw.Divider(),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "TOTAL",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      CurrencyFormatter.format(widget.order.total),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      messenger.showSnackBar(
        const SnackBar(
          content: Text("Receipt printed (PDF)"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Error printing: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    }

    if (mounted) {
      setState(() => _isPrinting = false);
    }
  }

  /// ---------------- BLUETOOTH PRINT ----------------
  Future<void> _printToBluetoothPrinter() async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    if (!_printerService.isConnected) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PrinterScanPage()),
      );

      if (!_printerService.isConnected) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Please connect a Bluetooth printer first"),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isPrinting = true);

    try {
      await _printerService.printReceipt(widget.order);

      messenger.showSnackBar(
        const SnackBar(
          content: Text("Receipt printed successfully"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Error printing: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    }

    if (mounted) {
      setState(() => _isPrinting = false);
    }
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,

        appBar: AppBar(
          title: const Text(AppStrings.receipt),
          backgroundColor: const Color.fromARGB(255, 93, 119, 86),
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.appName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    DateFormatter.formatDateTimeForReceipt(
                        widget.order.createdAt),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// RECEIPT CARD
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),

                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.black.withOpacity(.05),
                    )
                  ],
                ),

                child: Column(
                  children: [

                    /// ITEMS
                    ...widget.order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),

                        child: Row(
                          children: [

                            Expanded(
                              child: Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            Text(
                              "x${item.quantity}",
                              style: const TextStyle(fontSize: 13),
                            ),

                            const SizedBox(width: 8),

                            Text(
                              CurrencyFormatter.format(item.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 92, 151, 115),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 20),

                    /// TOTAL
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        const Text(
                          "TOTAL",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          CurrencyFormatter.format(widget.order.total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 116, 182, 114),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// BUTTONS
              Row(
                children: [

                  Expanded(
                    child: CustomButton(
                      text: "Export PDF",
                      icon: Icons.picture_as_pdf,
                      isOutlined: true,
                      isLoading: _isPrinting,
                      onPressed: _isPrinting ? null : _printReceipt,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: CustomButton(
                      text: "Print",
                      icon: Icons.print,
                      isLoading: _isPrinting,
                      onPressed:
                          _isPrinting ? null : _printToBluetoothPrinter,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              /// BLUETOOTH STATUS
              Card(
                child: ListTile(
                  dense: true,

                  leading: Icon(
                    _printerService.isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,

                    color: _printerService.isConnected
                        ? Colors.green
                        : Colors.grey,
                  ),

                  title: Text(
                    _printerService.isConnected
                        ? "Connected: ${_printerService.connectedDevice?.name}"
                        : "Bluetooth printer not connected",
                    style: const TextStyle(fontSize: 13),
                  ),

                  trailing: TextButton(
                    child: const Text("Select"),

                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrinterScanPage(),
                        ),
                      ).then((_) {
                        if (mounted) setState(() {});
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /// DONE BUTTON
              CustomButton(
                text: "Selesai",
                icon: Icons.check_circle,

                onPressed: () async {
                  final navigator = Navigator.of(context);

                  final authState = context.read<AuthBloc>().state;

                  if (authState is AuthAuthenticated) {
                    context.read<HistoryBloc>().add(
                          LoadHistoryEvent(userId: authState.user.id),
                        );
                  }

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('show_history_after_order', true);

                  if (mounted) {
                    navigator.popUntil((route) => route.isFirst);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}