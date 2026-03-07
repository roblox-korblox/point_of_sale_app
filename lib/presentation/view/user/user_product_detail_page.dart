import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/product_model.dart';
import '../../bloc/order/order_bloc.dart';
import '../../bloc/order/order_event.dart';

class UserProductDetailPage extends StatelessWidget {
  final ProductModel product;

  const UserProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Produk'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
        ),
        body: SingleChildScrollView(
          padding: Responsive.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image
              Container(
                height: isMobile ? 250 : 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  child: product.imagePath != null
                      ? Image.file(
                          File(product.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.background,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 80,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.background,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Product Name
              Text(
                product.name,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    mobile: AppSizes.fontSizeXL,
                    tablet: 28,
                    desktop: 32,
                  ),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Category
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.paddingXS),
                  Text(
                    'Kategori: ${product.categoryEnum.name}',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        mobile: AppSizes.fontSizeM,
                        tablet: AppSizes.fontSizeL,
                      ),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Price Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Harga',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeM,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingS),
                      if (product.hasDiscount) ...[
                        Row(
                          children: [
                            Text(
                              CurrencyFormatter.format(product.price),
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveFontSize(
                                  context,
                                  mobile: AppSizes.fontSizeL,
                                  tablet: AppSizes.fontSizeXL,
                                ),
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: AppSizes.paddingM),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingS,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusS,
                                ),
                              ),
                              child: Text(
                                '${product.discount}% OFF',
                                style: const TextStyle(
                                  fontSize: AppSizes.fontSizeS,
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.paddingS),
                      ],
                      Text(
                        CurrencyFormatter.format(product.finalPrice),
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            mobile: AppSizes.fontSizeXL,
                            tablet: 32,
                            desktop: 36,
                          ),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Stock Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 24,
                            color: product.stock > 0
                                ? AppColors.available
                                : AppColors.error,
                          ),
                          const SizedBox(width: AppSizes.paddingS),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Stok Tersedia',
                                style: TextStyle(
                                  fontSize: AppSizes.fontSizeM,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${product.stock} unit',
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveFontSize(
                                    context,
                                    mobile: AppSizes.fontSizeL,
                                    tablet: AppSizes.fontSizeXL,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: product.stock > 0
                                      ? AppColors.available
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingM,
                          vertical: AppSizes.paddingS,
                        ),
                        decoration: BoxDecoration(
                          color:
                              product.isAvailable &&
                                  !product.isOutOfStock &&
                                  product.stock > 0
                              ? AppColors.available.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                          border: Border.all(
                            color:
                                product.isAvailable &&
                                    !product.isOutOfStock &&
                                    product.stock > 0
                                ? AppColors.available
                                : AppColors.error,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          product.isAvailable &&
                                  !product.isOutOfStock &&
                                  product.stock > 0
                              ? 'Tersedia'
                              : 'Tidak Tersedia',
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeM,
                            fontWeight: FontWeight.bold,
                            color:
                                product.isAvailable &&
                                    !product.isOutOfStock &&
                                    product.stock > 0
                                ? AppColors.available
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Description Section
              if (product.description != null &&
                  product.description!.isNotEmpty) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description,
                              size: 24,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSizes.paddingS),
                            Text(
                              'Deskripsi',
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveFontSize(
                                  context,
                                  mobile: AppSizes.fontSizeL,
                                  tablet: AppSizes.fontSizeXL,
                                ),
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        Text(
                          product.description!,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveFontSize(
                              context,
                              mobile: AppSizes.fontSizeM,
                              tablet: AppSizes.fontSizeL,
                            ),
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingL),
              ],

              // Add to Cart Button
              if (product.isAvailable &&
                  !product.isOutOfStock &&
                  product.stock > 0)
                CustomButton(
                  text: AppStrings.addToOrder,
                  onPressed: () {
                    context.read<OrderBloc>().add(
                      AddToCartEvent(product: product),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Produk ditambahkan ke keranjang'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: Icons.add_shopping_cart,
                )
              else
                CustomButton(
                  text: 'Tidak Tersedia',
                  onPressed: null,
                  backgroundColor: AppColors.error,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
