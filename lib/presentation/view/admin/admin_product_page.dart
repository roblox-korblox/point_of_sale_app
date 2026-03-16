import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/strings.dart';
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

class AdminProductPage extends StatefulWidget {
  const AdminProductPage({super.key});

  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<AdminProductPage> {
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  static const Color _bgColor = Color(0xFFF3F6F2);
  static const Color _softGreen = Color(0xFFE4F0E6);
  static const Color _primaryGreen = Color(0xFF2E9E4D);
  static const Color _darkText = Color(0xFF1D1D1F);
  static const Color _softText = Color(0xFF6E6E73);

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const LoadProductsEvent());
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
        context.read<ProductBloc>().add(
          LoadProductsByCategoryEvent(_selectedCategory),
        );
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
      context.read<ProductBloc>().add(
        LoadProductsByCategoryEvent(category),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _darkText,
        title: const Text(
          AppStrings.products,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: _darkText,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeroCard(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            child: Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                children: [
                  CustomTextField(
                    controller: _searchController,
                    hint: AppStrings.search,
                    prefixIcon: const Icon(Icons.search_rounded),
                    onChanged: _onSearch,
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  _buildCategoryFilter(context),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                              itemCount: state.products.length,
                              itemBuilder: (context, index) {
                                final product = state.products[index];
                                return _buildProductCard(context, product);
                              },
                            )
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: AppSizes.paddingM,
                                mainAxisSpacing: AppSizes.paddingM,
                                childAspectRatio: isTablet ? 1.08 : 0.92,
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
                      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminProductFormPage(),
            ),
          ).then((_) {
            if (mounted) {
              context.read<ProductBloc>().add(const LoadProductsEvent());
            }
          });
        },
        backgroundColor: _primaryGreen,
        elevation: 6,
        child: const Icon(Icons.add_rounded, color: Colors.white),
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
          SizedBox(
            width: 60,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 30,
                color: _primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    Widget chip(String label, String value) {
      final isSelected = _selectedCategory == value;

      return ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) _onCategoryChanged(value);
        },
        showCheckmark: false,
        selectedColor: _primaryGreen,
        backgroundColor: const Color(0xFFF5F7F5),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : _darkText,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(
          color: isSelected ? _primaryGreen : const Color(0xFFE5EAE5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      );
    }

    return isMobile
        ? Wrap(
            spacing: AppSizes.paddingS,
            runSpacing: AppSizes.paddingS,
            alignment: WrapAlignment.start,
            children: [
              chip('Semua', 'all'),
              chip(AppStrings.food, 'food'),
              chip(AppStrings.drink, 'drink'),
            ],
          )
        : Row(
            children: [
              Expanded(child: chip('Semua', 'all')),
              const SizedBox(width: AppSizes.paddingS),
              Expanded(child: chip(AppStrings.food, 'food')),
              const SizedBox(width: AppSizes.paddingS),
              Expanded(child: chip(AppStrings.drink, 'drink')),
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
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(product, size: 76),
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
                  const SizedBox(height: 8),
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
                        textColor:
                            product.isAvailable ? _primaryGreen : Colors.redAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (product.hasDiscount)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${AppStrings.productDiscount}: ${product.discount}%',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
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
                _buildActionIcon(
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
                        context.read<ProductBloc>().add(
                              const LoadProductsEvent(),
                            );
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildActionIcon(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red,
                  onTap: () {
                    _showDeleteDialog(context, product);
                  },
                ),
              ],
            ),
          ],
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
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildProductImage(
                      product,
                      size: double.infinity,
                      expand: true,
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '-${product.discount}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
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
                fontSize: 12.5,
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
                  child: _buildMiniTag('Stock: ${product.stock}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildWideActionButton(
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
                          context.read<ProductBloc>().add(
                                const LoadProductsEvent(),
                              );
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildWideActionButton(
                    label: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    color: Colors.redAccent,
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
    );
  }

  Widget _buildProductImage(
    ProductModel product, {
    required dynamic size,
    bool expand = false,
  }) {
    return Container(
      width: expand ? null : size as double,
      height: expand ? null : size as double,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: product.imagePath != null
            ? Image.file(
                File(product.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: _softText,
                      size: 32,
                    ),
                  );
                },
              )
            : const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: _softText,
                  size: 32,
                ),
              ),
      ),
    );
  }

  Widget _buildMiniTag(
    String text, {
    Color textColor = _darkText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildWideActionButton({
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
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
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
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          AppStrings.deleteProduct,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
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