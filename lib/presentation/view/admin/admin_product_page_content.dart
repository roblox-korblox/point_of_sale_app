import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/empty_widget.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/product/product_state.dart';
import 'admin_product_form_page.dart';

class AdminProductPageContent extends StatefulWidget {
  const AdminProductPageContent({super.key});

  @override
  State<AdminProductPageContent> createState() => _AdminProductPageContentState();
}

class _AdminProductPageContentState extends State<AdminProductPageContent> {
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
          child: BlocConsumer<ProductBloc, ProductState>(
            listener: (context, state) {
              if (state is ProductSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is ProductError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is ProductLoading) {
                return const LoadingWidget();
              } else if (state is ProductLoaded) {
                if (state.products.isEmpty) {
                  return const EmptyWidget(
                    message: AppStrings.noData,
                    icon: Icons.inventory_2_outlined,
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = Responsive.isMobile(context);
                    final isTablet = Responsive.isTablet(context);
                    final crossAxisCount = Responsive.getGridCrossAxisCount(context);
                    
                    return isMobile
                        ? ListView.builder(
                            padding: const EdgeInsets.all(AppSizes.paddingM),
                            itemCount: state.products.length,
                            itemBuilder: (context, index) {
                              final product = state.products[index];
                              return _buildProductCard(context, product);
                            },
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(AppSizes.paddingM),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: AppSizes.paddingM,
                              mainAxisSpacing: AppSizes.paddingM,
                              childAspectRatio: isTablet ? 3 : 4,
                            ),
                            itemCount: state.products.length,
                            itemBuilder: (context, index) {
                              final product = state.products[index];
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
                  label: const Text('Semua'),
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
    final isTablet = Responsive.isTablet(context);
    
    return Card(
      margin: EdgeInsets.only(
        bottom: isMobile ? AppSizes.paddingM : AppSizes.paddingS,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: isMobile || isTablet
          ? ListTile(
              leading: CircleAvatar(
                radius: isMobile ? 25 : 30,
                backgroundColor: AppColors.background,
                backgroundImage: product.imagePath != null
                    ? FileImage(File(product.imagePath!))
                    : null,
                child: product.imagePath == null
                    ? const Icon(Icons.image_not_supported, color: AppColors.textSecondary)
                    : null,
              ),
              title: Text(
                product.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${AppStrings.productCategory}: ${product.categoryEnum.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${AppStrings.productPrice}: ${CurrencyFormatter.format(product.price)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.hasDiscount)
                    Text(
                      '${AppStrings.productDiscount}: ${product.discount}%',
                      style: const TextStyle(color: AppColors.success),
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '${AppStrings.productStock}: ${product.stock}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.isAvailable ? AppStrings.available : AppStrings.notAvailable,
                    style: TextStyle(
                      color: product.isAvailable ? AppColors.available : AppColors.error,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () {
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
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () {
                      _showDeleteDialog(context, product);
                    },
                  ),
                ],
              ),
              isThreeLine: false,
            )
          : GridTile(
              header: GridTileBar(
                backgroundColor: Colors.black54,
                title: Text(
                  product.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: AppSizes.fontSizeS),
                ),
              ),
              child: Stack(
                children: [
                  product.imagePath != null
                      ? Image.file(
                          File(product.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(Icons.image_not_supported, size: 48),
                        ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.paddingS),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(AppSizes.radiusM),
                          bottomRight: Radius.circular(AppSizes.radiusM),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CurrencyFormatter.format(product.price),
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: AppSizes.fontSizeM,
                            ),
                          ),
                          Text(
                            'Stok: ${product.stock}',
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: AppSizes.fontSizeS,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              footer: GridTileBar(
                backgroundColor: Colors.black87,
                leading: IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () {
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
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: () {
                    _showDeleteDialog(context, product);
                  },
                ),
              ),
            ),
    );
  }

  void _showDeleteDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            child: const Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

