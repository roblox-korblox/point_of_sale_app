import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/empty_widget.dart';
import '../../../data/models/product_model.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/product/product_state.dart';
import '../../bloc/order/order_bloc.dart';
import '../../bloc/order/order_event.dart';
import 'user_product_detail_page.dart';
import 'dart:io';

class UserProductPageContent extends StatefulWidget {
  const UserProductPageContent({super.key});

  @override
  State<UserProductPageContent> createState() => _UserProductPageContentState();
}

class _UserProductPageContentState extends State<UserProductPageContent> {
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductBloc>().add(const LoadProductsEvent());
        context.read<OrderBloc>().add(const LoadCurrentCartEvent());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      if (_selectedCategory == 'all') {
        context.read<ProductBloc>().add(const LoadProductsEvent());
      } else {
        context.read<ProductBloc>().add(LoadProductsByCategoryEvent(_selectedCategory));
      }
    } else {
      context.read<ProductBloc>().add(SearchProductsEvent(query));
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    if (category == 'all') {
      context.read<ProductBloc>().add(const LoadProductsEvent());
    } else {
      context.read<ProductBloc>().add(LoadProductsByCategoryEvent(category));
    }
  }

  void _addToCart(BuildContext context, ProductModel product) {
    if (!product.isAvailable || product.isOutOfStock || product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product not available'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<OrderBloc>().add(AddToCartEvent(product: product));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product added to cart'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            children: [
              CustomTextField(
                controller: _searchController,
                hint: AppStrings.search,
                prefixIcon: const Icon(Icons.search),
                onChanged: _onSearch,
              ),
              const SizedBox(height: AppSizes.paddingM),
              _buildCategoryFilter(context),
            ],
          ),
        ),
        // Product List
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const LoadingWidget();
              } else if (state is ProductLoaded) {
                final availableProducts = state.products
                    .where((p) => p.isAvailable && !p.isOutOfStock && p.stock > 0)
                    .toList();

                if (availableProducts.isEmpty) {
                  return const EmptyWidget(
                    message: AppStrings.noData,
                    icon: Icons.inventory_2_outlined,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = Responsive.isMobile(context);
                    final isTablet = Responsive.isTablet(context);
                    final crossAxisCount = Responsive.getGridCrossAxisCountForProducts(context);
                    
                    return GridView.builder(
                      padding: Responsive.getResponsivePadding(context),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: AppSizes.paddingM,
                        mainAxisSpacing: AppSizes.paddingM,
                        childAspectRatio: isMobile ? 0.55 : (isTablet ? 0.65 : 0.75),
                      ),
                      itemCount: availableProducts.length,
                      itemBuilder: (context, index) {
                        final product = availableProducts[index];
                        return _buildProductCard(context, product);
                      },
                    );
                  },
                );
              } else if (state is ProductError) {
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
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return isMobile
        ? Wrap(
            spacing: AppSizes.paddingS,
            runSpacing: AppSizes.paddingS,
            alignment: WrapAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Semua'),
                selected: _selectedCategory == 'all',
                onSelected: (selected) {
                  if (selected) _onCategoryChanged('all');
                },
              ),
              ChoiceChip(
                label: const Text(AppStrings.food),
                selected: _selectedCategory == 'food',
                onSelected: (selected) {
                  if (selected) _onCategoryChanged('food');
                },
              ),
              ChoiceChip(
                label: const Text(AppStrings.drink),
                selected: _selectedCategory == 'drink',
                onSelected: (selected) {
                  if (selected) _onCategoryChanged('drink');
                },
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedCategory == 'all',
                  onSelected: (selected) {
                    if (selected) _onCategoryChanged('all');
                  },
                ),
              ),
              const SizedBox(width: AppSizes.paddingS),
              Expanded(
                child: ChoiceChip(
                  label: const Text(AppStrings.food),
                  selected: _selectedCategory == 'food',
                  onSelected: (selected) {
                    if (selected) _onCategoryChanged('food');
                  },
                ),
              ),
              const SizedBox(width: AppSizes.paddingS),
              Expanded(
                child: ChoiceChip(
                  label: const Text(AppStrings.drink),
                  selected: _selectedCategory == 'drink',
                  onSelected: (selected) {
                    if (selected) _onCategoryChanged('drink');
                  },
                ),
              ),
            ],
          );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final isMobile = Responsive.isMobile(context);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProductDetailPage(product: product),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.radiusM),
                      topRight: Radius.circular(AppSizes.radiusM),
                    ),
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
                                    size: 40,
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
                                size: 40,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                        child: Text(
                          '${product.discount}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(
                  isMobile ? 6 : 8,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        SizedBox(
                          height: isMobile ? 30 : 34,
                          child: Text(
                            product.name,
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveFontSize(
                                context,
                                mobile: AppSizes.fontSizeM,
                                tablet: AppSizes.fontSizeL,
                                desktop: AppSizes.fontSizeXL,
                              ),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Price
                        Row(
                          children: [
                            if (product.hasDiscount) ...[
                              Flexible(
                                child: Text(
                                  CurrencyFormatter.format(product.price),
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveFontSize(
                                      context,
                                      mobile: AppSizes.fontSizeXS,
                                      tablet: AppSizes.fontSizeS,
                                    ),
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 3),
                            ],
                            Flexible(
                              child: Text(
                                CurrencyFormatter.format(product.finalPrice),
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveFontSize(
                                    context,
                                    mobile: AppSizes.fontSizeM,
                                    tablet: AppSizes.fontSizeL,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Stock and Button
                        SizedBox(
                          height: 22,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Stock: ${product.stock}',
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveFontSize(
                                      context,
                                      mobile: 9,
                                      tablet: AppSizes.fontSizeS,
                                    ),
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                flex: 3,
                                child: CustomButton(
                                  text: 'Add',
                                  onPressed: () => _addToCart(context, product),
                                  height: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

