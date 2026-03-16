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
import '../../bloc/order/order_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import 'user_cart_page.dart';
import 'user_product_detail_page.dart';
import 'dart:io';

class UserProductPage extends StatefulWidget {
  const UserProductPage({super.key});

  @override
  State<UserProductPage> createState() => _UserProductPageState();
}

class _UserProductPageState extends State<UserProductPage> {
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const LoadProductsEvent());
    context.read<OrderBloc>().add(const LoadCurrentCartEvent());
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 160, 218, 158),
        title: const Text(AppStrings.appName),
        actions: [
          BlocBuilder<OrderBloc, OrderState>(
            builder: (context, orderState) {
              final cartItemCount =
                  orderState is CartLoaded ? orderState.cartItems.length : 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserCartPage(),
                        ),
                      ).then((_) {
                        if (mounted) {
                          context
                              .read<OrderBloc>()
                              .add(const LoadCurrentCartEvent());
                        }
                      });
                    },
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: AppColors.error,
                        child: Text(
                          "$cartItemCount",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutEvent());
            },
          ),
        ],
      ),

      body: Column(
        children: [

          /// SEARCH + CATEGORY
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [

                /// SEARCH
                CustomTextField(
                  controller: _searchController,
                  hint: AppStrings.search,
                  prefixIcon: const Icon(Icons.search),
                  onChanged: _onSearch,
                ),

                const SizedBox(height: 12),

                _buildCategoryFilter(context),
              ],
            ),
          ),

          /// PRODUCT GRID
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {

                if (state is ProductLoading) {
                  return const LoadingWidget();
                }

                if (state is ProductLoaded) {

                  final products = state.products
                      .where((p) =>
                          p.isAvailable &&
                          !p.isOutOfStock &&
                          p.stock > 0)
                      .toList();

                  if (products.isEmpty) {
                    return const EmptyWidget(
                      message: AppStrings.noData,
                      icon: Icons.inventory,
                    );
                  }

                  final crossAxisCount =
                      Responsive.getGridCrossAxisCountForProducts(context);

                  return GridView.builder(
                    padding: Responsive.getResponsivePadding(context),

                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.70,
                    ),

                    itemCount: products.length,

                    itemBuilder: (context, index) {
                      return _buildProductCard(context, products[index]);
                    },
                  );
                }

                if (state is ProductError) {
                  return Center(child: Text(state.message));
                }

                return const EmptyWidget(message: AppStrings.noData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [

        ChoiceChip(
          label: const Text("All"),
          selected: _selectedCategory == "all",
          onSelected: (v) {
            if (v) _onCategoryChanged("all");
          },
        ),

        ChoiceChip(
          label: const Text(AppStrings.food),
          selected: _selectedCategory == "food",
          onSelected: (v) {
            if (v) _onCategoryChanged("food");
          },
        ),

        ChoiceChip(
          label: const Text(AppStrings.drink),
          selected: _selectedCategory == "drink",
          onSelected: (v) {
            if (v) _onCategoryChanged("drink");
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProductDetailPage(product: product),
          ),
        );
      },

      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            /// IMAGE
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: product.imagePath != null
                    ? Image.file(
                        File(product.imagePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.fastfood),
                        ),
                      ),
              ),
            ),

            /// INFO
            Padding(
              padding: const EdgeInsets.all(10),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    CurrencyFormatter.format(product.finalPrice),
                    style: const TextStyle(
                      color: Color.fromARGB(255, 139, 236, 152),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [

                      Expanded(
                        child: Text(
                          "Stok ${product.stock}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 28,
                        child: CustomButton(
                          text: "+",
                          onPressed: () =>
                              _addToCart(context, product),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}