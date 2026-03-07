import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/order_model.dart';

class AdminHistoryDetailPage extends StatelessWidget {
  final OrderModel order;

  const AdminHistoryDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.orderDetail),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'ID Pesanan: ${order.id}',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeL,
                              fontWeight: FontWeight.bold,
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
                            borderRadius: BorderRadius.circular(4),
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
                    const SizedBox(height: AppSizes.paddingM),
                    _buildInfoRow('Tanggal', DateFormatter.formatDateTime(order.createdAt)),
                    if (order.completedAt != null)
                      _buildInfoRow('Selesai', DateFormatter.formatDateTime(order.completedAt!)),
                    _buildInfoRow('Metode Pembayaran', order.paymentMethod.toUpperCase()),
                    if (order.userId != null)
                      _buildInfoRow('User ID', order.userId!),
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
            ...order.items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppSizes.paddingM),
                  title: Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSizes.paddingS),
                      Text('${AppStrings.quantity}: ${item.quantity}'),
                      if (item.discount > 0)
                        Text('${AppStrings.discount}: ${item.discount}%'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (item.discount > 0)
                        Text(
                          CurrencyFormatter.format(item.product.price),
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textSecondary,
                            fontSize: AppSizes.fontSizeS,
                          ),
                        ),
                      Text(
                        CurrencyFormatter.format(item.finalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Total: ${CurrencyFormatter.format(item.total)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                        Text(CurrencyFormatter.format(order.subtotal)),
                      ],
                    ),
                    if (order.totalDiscount > 0) ...[
                      const SizedBox(height: AppSizes.paddingS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Diskon:'),
                          Text(
                            CurrencyFormatter.format(order.totalDiscount),
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
                          CurrencyFormatter.format(order.total),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


