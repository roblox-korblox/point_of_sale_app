import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'admin_history_detail_page.dart';

class AdminHistoryPageContent extends StatefulWidget {
  const AdminHistoryPageContent({super.key});

  @override
  State<AdminHistoryPageContent> createState() => _AdminHistoryPageContentState();
}

class _AdminHistoryPageContentState extends State<AdminHistoryPageContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HistoryBloc>().add(const LoadHistoryEvent());
      }
    });
  }

  void _loadHistory() {
    if (!mounted) return;
    context.read<HistoryBloc>().add(const LoadHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading) {
          return const LoadingWidget();
        } else if (state is HistoryLoaded) {
          if (state.orders.isEmpty) {
            return const EmptyWidget(
              message: 'Tidak ada riwayat pesanan',
              icon: Icons.history,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadHistory();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return _buildOrderCard(context, order);
              },
            ),
          );
        } else if (state is HistoryError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: AppSizes.paddingM),
                ElevatedButton(
                  onPressed: _loadHistory,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        } else {
          return const EmptyWidget(message: AppStrings.noData);
        }
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminHistoryDetailPage(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'ID: ${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppSizes.fontSizeM,
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
                      borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: AppSizes.paddingS),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatDateTime(order.createdAt),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontSizeS,
                    ),
                  ),
                ],
              ),
              if (order.userId != null) ...[
                const SizedBox(height: AppSizes.paddingS),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'User ID: ${order.userId}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppSizes.fontSizeS,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSizes.paddingS),
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontSizeS,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    order.paymentMethod == 'cash' ? Icons.money : Icons.qr_code,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.paymentMethod.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontSizeS,
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSizes.paddingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeM,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(order.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.fontSizeXL,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

