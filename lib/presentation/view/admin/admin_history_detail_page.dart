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

  static const Color _bgColor = Color(0xFFF3F6F2);
  static const Color _softGreen = Color(0xFFE4F0E6);
  static const Color _primaryGreen = Color(0xFF2E9E4D);
  static const Color _darkText = Color(0xFF1D1D1F);
  static const Color _softText = Color(0xFF6E6E73);

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = order.status.toLowerCase() == 'completed';

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _darkText,
        title: const Text(
          AppStrings.orderDetail,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: _darkText,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroCard(isCompleted),
            const SizedBox(height: AppSizes.paddingL),

            _buildSectionTitle('Informasi Pesanan'),
            const SizedBox(height: AppSizes.paddingM),

            Container(
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
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ID Pesanan #${order.id}',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeL,
                              fontWeight: FontWeight.w800,
                              color: _darkText,
                            ),
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
                              fontSize: AppSizes.fontSizeS,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingL),
                    _buildInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: DateFormatter.formatDateTime(order.createdAt),
                    ),
                    if (order.completedAt != null)
                      _buildInfoRow(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Completed',
                        value: DateFormatter.formatDateTime(order.completedAt!),
                      ),
                    _buildInfoRow(
                      icon: order.paymentMethod == 'cash'
                          ? Icons.payments_outlined
                          : Icons.qr_code_2_rounded,
                      label: 'Payment Method',
                      value: order.paymentMethod.toUpperCase(),
                    ),
                    if (order.userId != null)
                      _buildInfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'User ID',
                        value: order.userId!,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.paddingL),

            _buildSectionTitle('Items'),
            const SizedBox(height: AppSizes.paddingM),

            ...order.items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
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
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _softGreen,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: _primaryGreen,
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: _darkText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${AppStrings.quantity}: ${item.quantity}',
                              style: const TextStyle(
                                color: _softText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (item.discount > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${AppStrings.discount}: ${item.discount}%',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingS),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (item.discount > 0)
                            Text(
                              CurrencyFormatter.format(item.product.price),
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: _softText,
                                fontSize: AppSizes.fontSizeS,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(item.finalPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _primaryGreen,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Total: ${CurrencyFormatter.format(item.total)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _darkText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.paddingS),

            _buildSectionTitle('Ringkasan Pembayaran'),
            const SizedBox(height: AppSizes.paddingM),

            Container(
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
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      label: 'Subtotal',
                      value: CurrencyFormatter.format(order.subtotal),
                    ),
                    if (order.totalDiscount > 0) ...[
                      const SizedBox(height: AppSizes.paddingS),
                      _buildSummaryRow(
                        label: 'Discount',
                        value: CurrencyFormatter.format(order.totalDiscount),
                        valueColor: Colors.orange,
                      ),
                    ],
                    const SizedBox(height: AppSizes.paddingM),
                    const Divider(color: Color(0xFFEDEDED), height: 1),
                    const SizedBox(height: AppSizes.paddingM),
                    _buildSummaryRow(
                      label: AppStrings.total,
                      value: CurrencyFormatter.format(order.total),
                      isTotal: true,
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

  Widget _buildHeroCard(bool isCompleted) {
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
              children: [
                const Text(
                  'Detail Pesanan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCompleted
                      ? 'Pesanan ini sudah selesai dan tercatat dengan baik.'
                      : 'Pesanan ini masih dalam proses atau belum selesai.',
                  style: const TextStyle(
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
            child: Icon(
              isCompleted
                  ? Icons.receipt_long_rounded
                  : Icons.pending_actions_rounded,
              size: 30,
              color: isCompleted ? _primaryGreen : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppSizes.fontSizeXL,
        fontWeight: FontWeight.w800,
        color: _darkText,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _softText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color valueColor = _darkText,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? AppSizes.fontSizeL : AppSizes.fontSizeM,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? _darkText : _softText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? AppSizes.fontSizeXL : AppSizes.fontSizeM,
            fontWeight: FontWeight.w800,
            color: isTotal ? _primaryGreen : valueColor,
          ),
        ),
      ],
    );
  }
}