import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../data/models/product_model.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/product/product_state.dart';
import 'admin_product_form_page.dart';

class AdminProductPageContent extends StatefulWidget {
  const AdminProductPageContent({super.key});

  @override
  State<AdminProductPageContent> createState() =>
      _AdminProductPageContentState();
}

class _AdminProductPageContentState extends State<AdminProductPageContent> {
  static const Color _bgColor = Color(0xFFF3F6F2);
  static const Color _softGreen = Color(0xFFE4F0E6);
  static const Color _primaryGreen = Color(0xFF2E9E4D);
  static const Color _darkText = Color(0xFF1D1D1F);
  static const Color _softText = Color(0xFF6E6E73);

  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductBloc>().add(const LoadProductsEvent());
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
        context
            .read<ProductBloc>()
            .add(LoadProductsByCategoryEvent(_selectedCategory));
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      child: Column(
        children: [
          _buildHeroCard(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: CustomTextField(
                      controller: _searchController,
                      hint: AppStrings.search,
                      prefixIcon: const Icon(Icons.search_rounded),
                      onChanged: _onSearch,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingM),
                _buildCategoryFilter(context),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state is ProductSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                } else if (state is ProductError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ProductLoading) {
                  return const LoadingWidget();
                } else if (state is ProductLoaded) {
                  if (state.products.isEmpty) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const EmptyWidget(
                        message: AppStrings.noData,
                        icon: Icons.inventory_2_outlined,
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = Responsive.isMobile(context);
                      final isTablet = Responsive.isTablet(context);
                      final crossAxisCount =
                          Responsive.getGridCrossAxisCount(context);

                      return isMobile
                          ? ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.all(AppSizes.paddingM),
                              itemCount: state.products.length,
                              itemBuilder: (context, index) {
                                final product = state.products[index];
                                return _buildProductCard(context, product);
                              },
                            )
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.all(AppSizes.paddingM),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: AppSizes.paddingM,
                                mainAxisSpacing: AppSizes.paddingM,
                                childAspectRatio: isTablet ? 1.08 : 0.88,
                              ),
                              itemCount: state.products.length,
                              itemBuilder: (context, index) {
                                final product = state.products[index];
                                return _buildDesktopProductCard(
                                  context,
                                  product,
                                );
                              },
                            );
                    },
                  );
                } else if (state is ProductError) {
                  return Center(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                } else {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const EmptyWidget(message: AppStrings.noData),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola Produk',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _darkText,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Cari, filter, edit, dan hapus produk dengan tampilan yang lebih rapi.',
                  style: TextStyle(
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
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 30,
              color: _primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    Widget chip({
      required String value,
      required String label,
    }) {
      final bool selected = _selectedCategory == value;

      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (isSelected) {
          if (isSelected) _onCategoryChanged(value);
        },
        backgroundColor: Colors.white,
        selectedColor: _softGreen,
        labelStyle: TextStyle(
          color: selected ? _primaryGreen : _darkText,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(
          color: selected ? _primaryGreen : const Color(0xFFE5EAE5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      );
    }

    if (isMobile) {
      return Wrap(
        spacing: AppSizes.paddingS,
        runSpacing: AppSizes.paddingS,
        alignment: WrapAlignment.start,
        children: [
          chip(value: 'all', label: 'All'),
          chip(value: 'food', label: AppStrings.food),
          chip(value: 'drink', label: AppStrings.drink),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: chip(value: 'all', label: 'All')),
        const SizedBox(width: AppSizes.paddingS),
        Expanded(child: chip(value: 'food', label: AppStrings.food)),
        const SizedBox(width: AppSizes.paddingS),
        Expanded(child: chip(value: 'drink', label: AppStrings.drink)),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminProductFormPage(product: product),
            ),
          ).then((_) {
            if (mounted) {
              context.read<ProductBloc>().add(const LoadProductsEvent());
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(product, 76, 76, radius: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: _darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMiniTag(product.categoryEnum.name),
                        _buildMiniTag('Stock: ${product.stock}'),
                        _buildMiniTag(
                          product.isAvailable
                              ? AppStrings.available
                              : AppStrings.notAvailable,
                          isPositive: product.isAvailable,
                        ),
                        if (product.hasDiscount)
                          _buildMiniTag(
                            '${product.discount}% off',
                            isPositive: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      CurrencyFormatter.format(product.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: _primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    color: _primaryGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AdminProductFormPage(product: product),
                        ),
                      ).then((_) {
                        if (mounted) {
                          context
                              .read<ProductBloc>()
                              .add(const LoadProductsEvent());
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    icon: Icons.delete_rounded,
                    color: AppColors.error,
                    onTap: () {
                      _showDeleteDialog(context, product);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopProductCard(BuildContext context, ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminProductFormPage(product: product),
            ),
          ).then((_) {
            if (mounted) {
              context.read<ProductBloc>().add(const LoadProductsEvent());
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: _buildProductImage(product, double.infinity, double.infinity,
                      radius: 22),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.categoryEnum.name,
                style: const TextStyle(
                  color: _softText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                CurrencyFormatter.format(product.price),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: _primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Stock: ${product.stock}',
                      style: const TextStyle(
                        color: _softText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (product.hasDiscount)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F6EC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${product.discount}% off',
                        style: const TextStyle(
                          color: _primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBottomAction(
                      label: 'Edit',
                      icon: Icons.edit_rounded,
                      color: _primaryGreen,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AdminProductFormPage(product: product),
                          ),
                        ).then((_) {
                          if (mounted) {
                            context
                                .read<ProductBloc>()
                                .add(const LoadProductsEvent());
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildBottomAction(
                      label: 'Delete',
                      icon: Icons.delete_rounded,
                      color: AppColors.error,
                      onTap: () {
                        _showDeleteDialog(context, product);
                      },
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

  Widget _buildProductImage(
    ProductModel product,
    double width,
    double height, {
    double radius = 18,
  }) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height == double.infinity ? null : height,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F6),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: product.imagePath != null
            ? Image.file(
                File(product.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: _softText,
                      size: 34,
                    ),
                  );
                },
              )
            : const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: _softText,
                  size: 34,
                ),
              ),
      ),
    );
  }

  Widget _buildMiniTag(String text, {bool isPositive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPositive ? const Color(0xFFE8F6EC) : const Color(0xFFF5F7F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isPositive ? _primaryGreen : _softText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: color),
      ),
    );
  }

  Widget _buildBottomAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(AppStrings.deleteProduct),
        content: Text(AppStrings.confirmDeleteProduct),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<ProductBloc>().add(DeleteProductEvent(product.id));
              Navigator.pop(context);
            },
            child: const Text(
              AppStrings.delete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}