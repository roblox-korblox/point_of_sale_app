import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../bloc/order/order_bloc.dart';
import '../../bloc/order/order_event.dart';
import '../../bloc/order/order_state.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/transaction/transaction_event.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/history/history_bloc.dart';
import '../../bloc/history/history_event.dart';
import 'user_receipt_page.dart';

class UserPaymentPage extends StatefulWidget {
  final int total;
  final String? userId;

  const UserPaymentPage({super.key, required this.total, this.userId});

  @override
  State<UserPaymentPage> createState() => _UserPaymentPageState();
}

class _UserPaymentPageState extends State<UserPaymentPage> {
  String _selectedPaymentMethod = 'cash';
  bool _showQRCode = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.payment),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total Amount
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingL),
                  child: Column(
                    children: [
                      const Text(
                        AppStrings.total,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeL,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingS),
                      Text(
                        CurrencyFormatter.format(widget.total),
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeXXXL,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),
              // Payment Method
              const Text(
                AppStrings.paymentMethod,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeXL,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),
              // Cash Option
              Card(
                child: RadioListTile<String>(
                  title: const Text(AppStrings.cash),
                  subtitle: const Text('Pay with cash'),
                  value: 'cash',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                      _showQRCode = false;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppSizes.paddingS),
              // QR Code Option
              Card(
                child: RadioListTile<String>(
                  title: const Text(AppStrings.qrCode),
                  subtitle: const Text('Pay with QR Code'),
                  value: 'qrcode',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                      _showQRCode = true;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),
              // QR Code Display
              if (_showQRCode && _selectedPaymentMethod == 'qrcode')
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingL),
                    child: Column(
                      children: [
                        const Text(
                          'Scan QR Code to pay',
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeL,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        QrImageView(
                          data:
                              'PAYMENT:${widget.total}:${DateTime.now().millisecondsSinceEpoch}',
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: AppColors.surface,
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        const Text(
                          'Please show this QR Code to the cashier',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSizes.paddingL),
              // Confirm Payment Button
              BlocConsumer<OrderBloc, OrderState>(
                listener: (context, state) {
                  if (state is OrderSuccess) {
                    // Create transaction
                    context.read<TransactionBloc>().add(
                      CreateTransactionEvent(state.order),
                    );

                    // Refresh history to show the new order
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated) {
                      context.read<HistoryBloc>().add(
                        LoadHistoryEvent(userId: authState.user.id),
                      );
                    }

                    // Navigate to receipt
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserReceiptPage(order: state.order),
                      ),
                    );
                  } else if (state is OrderError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return CustomButton(
                    text: AppStrings.pay,
                    onPressed: state is OrderLoading
                        ? null
                        : () {
                            final authState = context.read<AuthBloc>().state;
                            String? userId = widget.userId;
                            if (authState is AuthAuthenticated) {
                              userId = authState.user.id;
                            }

                            context.read<OrderBloc>().add(
                              CreateOrderEvent(
                                paymentMethod: _selectedPaymentMethod,
                                userId: userId,
                              ),
                            );
                          },
                    isLoading: state is OrderLoading,
                    icon: Icons.payment,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
