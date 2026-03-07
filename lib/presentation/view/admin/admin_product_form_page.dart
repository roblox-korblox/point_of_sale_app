import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';

class AdminProductFormPage extends StatefulWidget {
  final ProductModel? product;

  const AdminProductFormPage({super.key, this.product});

  @override
  State<AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends State<AdminProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _discountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCategory = 'food';
  bool _isAvailable = true;
  bool _isOutOfStock = false;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _discountController.text = widget.product!.discount.toString();
      _descriptionController.text = widget.product!.description ?? '';
      _selectedCategory = widget.product!.category;
      _isAvailable = widget.product!.isAvailable;
      _isOutOfStock = widget.product!.isOutOfStock;
      _imagePath = widget.product!.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _discountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = ProductModel(
        id:
            widget.product?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        price: int.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        isAvailable: _isAvailable,
        isOutOfStock: _isOutOfStock,
        discount: int.tryParse(_discountController.text) ?? 0,
        imagePath: _imagePath,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.product == null) {
        context.read<ProductBloc>().add(AddProductEvent(product));
      } else {
        context.read<ProductBloc>().add(UpdateProductEvent(product));
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.product == null
                ? AppStrings.addProduct
                : AppStrings.editProduct,
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusM,
                            ),
                            child: Image.file(
                              File(_imagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image,
                                size: 64,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: AppSizes.paddingS),
                              Text(
                                AppStrings.productImage,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingM),
                CustomTextField(
                  label: AppStrings.productName,
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.fieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingM),
                CustomTextField(
                  label: AppStrings.productPrice,
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.fieldRequired;
                    }
                    final price = int.tryParse(value);
                    if (price == null || price <= 0) {
                      return AppStrings.priceMustBeGreaterThanZero;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingM),
                CustomTextField(
                  label: AppStrings.productStock,
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.fieldRequired;
                    }
                    final stock = int.tryParse(value);
                    if (stock == null || stock < 0) {
                      return AppStrings.stockMustBeGreaterThanOrEqualZero;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingM),
                CustomTextField(
                  label: AppStrings.productDiscount,
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final discount = int.tryParse(value);
                      if (discount == null || discount < 0 || discount > 100) {
                        return AppStrings.discountMustBeBetween0And100;
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingM),
                CustomTextField(
                  label: AppStrings.productDescription,
                  controller: _descriptionController,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSizes.paddingM),
                // Category Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: AppStrings.productCategory,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                  ),
                  initialValue: _selectedCategory,
                  items: [
                    DropdownMenuItem(
                      value: 'food',
                      child: Text(ProductCategory.food.name),
                    ),
                    DropdownMenuItem(
                      value: 'drink',
                      child: Text(ProductCategory.drink.name),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSizes.paddingM),
                // Available Switch
                SwitchListTile(
                  title: const Text(AppStrings.available),
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _isAvailable = value;
                    });
                  },
                ),
                // Out of Stock Switch
                SwitchListTile(
                  title: const Text(AppStrings.outOfStock),
                  value: _isOutOfStock,
                  onChanged: (value) {
                    setState(() {
                      _isOutOfStock = value;
                    });
                  },
                ),
                const SizedBox(height: AppSizes.paddingL),
                CustomButton(
                  text: AppStrings.save,
                  onPressed: _saveProduct,
                  icon: Icons.save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
