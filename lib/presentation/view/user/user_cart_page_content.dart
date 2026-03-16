import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/empty_widget.dart';
import '../../bloc/order/order_bloc.dart';
import '../../bloc/order/order_event.dart';
import '../../bloc/order/order_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import 'user_payment_page.dart';
import 'dart:io';

class UserCartPageContent extends StatefulWidget {
  const UserCartPageContent({super.key});

  @override
  State<UserCartPageContent> createState() => _UserCartPageContentState();
}

class _UserCartPageContentState extends State<UserCartPageContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrderBloc>().add(const LoadCurrentCartEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is CartLoaded) {
          if (state.cartItems.isEmpty) {
            return const EmptyWidget(
              message: AppStrings.emptyCart,
              icon: Icons.shopping_cart_outlined,
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  itemCount: state.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = state.cartItems[index];
                    return _buildCartItem(item);
                  },
                ),
              ),
              // Total and Pay Button
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textHint.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
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
                        Flexible(
                          child: Text(
                            CurrencyFormatter.format(state.total),
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeXL,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingM),
                    CustomButton(
                      text: AppStrings.pay,
                      onPressed: () {
                        final authState = context.read<AuthBloc>().state;
                        final orderBloc = context.read<OrderBloc>();
                        String? userId;
                        if (authState is AuthAuthenticated) {
                          userId = authState.user.id;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserPaymentPage(
                              total: state.total,
                              userId: userId,
                            ),
                          ),
                        ).then((_) {
                          if (mounted) {
                            orderBloc.add(
                              const LoadCurrentCartEvent(),
                            );
                          }
                        });
                      },
                      icon: Icons.payment,
                    ),
                  ],
                ),
              ),
            ],
          );
        } else if (state is OrderLoading) {
          return const LoadingWidget();
        } else if (state is OrderError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: AppColors.error),
            ),
          );
        } else {
          return const EmptyWidget(message: AppStrings.emptyCart);
        }
      },
    );
  }

  Widget _buildCartItem(dynamic item) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSizes.paddingM),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.background,
          backgroundImage: item.product.imagePath != null
              ? FileImage(File(item.product.imagePath!))
              : null,
          child: item.product.imagePath == null
              ? const Icon(Icons.image_not_supported, color: AppColors.textSecondary)
              : null,
        ),
        title: Text(
          item.product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.paddingXS),
            Row(
              children: [
                if (item.product.hasDiscount)
                  Flexible(
                    child: Text(
                      CurrencyFormatter.format(item.product.price),
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        fontSize: AppSizes.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (item.product.hasDiscount)
                  const SizedBox(width: AppSizes.paddingXS),
                Flexible(
                  child: Text(
                    CurrencyFormatter.format(item.finalPrice),
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeM,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingXS),
            Text('${AppStrings.quantity}: ${item.quantity}'),
            Text(
              '${AppStrings.subtotal}: ${CurrencyFormatter.format(item.total)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        trailing: Builder(
          builder: (context) {
            final orderBloc = context.read<OrderBloc>();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (item.quantity > 1) {
                      orderBloc.add(
                        UpdateCartItemQuantityEvent(
                          productId: item.product.id,
                          quantity: item.quantity - 1,
                        ),
                      );
                    } else {
                      orderBloc.add(
                        RemoveFromCartEvent(item.product.id),
                      );
                    }
                  },
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeM,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    if (item.quantity < item.product.stock) {
                      orderBloc.add(
                        UpdateCartItemQuantityEvent(
                          productId: item.product.id,
                          quantity: item.quantity + 1,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Insufficient stock'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: () {
                    orderBloc.add(
                      RemoveFromCartEvent(item.product.id),
                    );
                  },
                ),
              ],
            );
          },
        ),
        isThreeLine: true,
      ),
    );
  }
}

