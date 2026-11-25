import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/loading_overlay.dart';
import 'stock_adjust_dialog.dart';
import '../widgets/transfer_stock_sheet.dart';
import '../utils/error_text.dart';
import '../utils/product_rules.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  /// If null, we're adding a new product. If non-null, we're editing.
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _categoryController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _lowStockController;

  bool _isLoading = false;
  bool get _isEditing => widget.product != null;

  // Dropdown selection state for the business-owned category list.
  // _categoryController is reused as the "type a new category" input in
  // BOTH the empty-state (no categories exist yet) and the "+ Create new"
  // reveal case — only one of those two is ever visible at once.
  String? _selectedCategory;
  static const String _createNewCategorySentinel = '__create_new_category__';

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _categoryController = TextEditingController(text: p?.category ?? '');
    _selectedCategory = p?.category;
    _costPriceController = TextEditingController(
      text: p != null ? p.costPriceUsd.toStringAsFixed(2) : '',
    );
    _sellPriceController = TextEditingController(
      text: p != null ? p.sellPriceUsd.toStringAsFixed(2) : '',
    );
    _quantityController = TextEditingController(
      text: p != null ? p.quantity.toString() : '',
    );
    _lowStockController = TextEditingController(
      text: (p?.lowStockThreshold ?? 5).toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _quantityController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateNonNegativeNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a valid non-negative number';
    }
    return null;
  }

  String? _validateNonNegativeInteger(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a valid non-negative whole number';
    }
    return null;
  }

  /// Resolves the final category value to save, handling the
  /// case-insensitive dedup: if the owner typed a "new" category that
  /// only differs in casing from one that already exists, reuse the
  /// existing casing instead of creating a near-duplicate.
  String? _resolveCategoryToSave() {
    final categories = ref.read(productCategoryProvider).valueOrNull ?? [];
    return resolveCategoryToSave(
      existingCategories: categories,
      selected: _selectedCategory,
      typed: _categoryController.text,
      createNewSentinel: _createNewCategorySentinel,
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final business = ref.read(currentBusinessProvider);
    if (business == null) {
      _showError('No business found. Please re-login.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final actions = ref.read(productActionsProvider);
      final resolvedCategory = _resolveCategoryToSave();

      if (_isEditing) {
        // When editing, quantity is not changed through this form —
        // stock changes go through the stock adjust dialog.
        final product = Product(
          id: widget.product!.id,
          inventoryId: widget.product!.inventoryId,
          businessId: business.id,
          name: _nameController.text.trim(),
          sku: _skuController.text.trim().isEmpty
              ? null
              : _skuController.text.trim(),
          category: resolvedCategory,
          costPriceUsd: double.parse(_costPriceController.text.trim()),
          sellPriceUsd: double.parse(_sellPriceController.text.trim()),
          quantity: widget.product!.quantity, // preserve current stock
          lowStockThreshold: int.parse(_lowStockController.text.trim()),
        );
        await actions.updateProduct(product);
      } else {
        // New product — id is generated by the repository
        final product = Product(
          id: null,
          businessId: business.id,
          name: _nameController.text.trim(),
          sku: _skuController.text.trim().isEmpty
              ? null
              : _skuController.text.trim(),
          category: resolvedCategory,
          costPriceUsd: double.parse(_costPriceController.text.trim()),
          sellPriceUsd: double.parse(_sellPriceController.text.trim()),
          quantity: int.parse(_quantityController.text.trim()),
          lowStockThreshold: int.parse(_lowStockController.text.trim()),
        );
        await actions.addProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Product updated' : 'Product added'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError(errorText(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Delete this product? This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(productActionsProvider).deleteProduct(widget.product!.id!);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product deleted')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError(errorText(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showStockAdjustDialog() {
    if (widget.product == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StockAdjustDialog(product: widget.product!),
    ).then((_) {
      // After stock adjust, pop back to list since the product data
      // in this form is now stale
      if (mounted) Navigator.of(context).pop();
    });
  }

  /// Builds the category field: a plain text field if this business has
  /// no categories yet, or a dropdown (plus "+ Create new category") once
  /// it does.
  Widget _buildCategoryField(List<String> categories) {
    if (categories.isEmpty) {
      return TextFormField(
        controller: _categoryController,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(Icons.category_outlined),
        ),
      );
    }

    // Dropdown's `value` must exactly match one of its `items`, or Flutter
    // throws — guard against a stale/mismatched selection defensively.
    final dropdownValue =
        (categories.contains(_selectedCategory) ||
            _selectedCategory == _createNewCategorySentinel)
        ? _selectedCategory
        : null;

    return DropdownButtonFormField<String>(
      initialValue: dropdownValue,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: [
        ...categories.map(
          (c) => DropdownMenuItem(
            value: c,
            child: Text(c, overflow: TextOverflow.ellipsis),
          ),
        ),
        const DropdownMenuItem(
          value: _createNewCategorySentinel,
          child: Text('+ Create new category'),
        ),
      ],
      onChanged: (value) {
        setState(() => _selectedCategory = value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(productCategoryProvider).valueOrNull ?? [];
    final showNewCategoryField =
        categories.isNotEmpty &&
        _selectedCategory == _createNewCategorySentinel;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Adjust stock',
              onPressed: _showStockAdjustDialog,
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Move to another location',
              onPressed: () async {
                final ok = await showTransferStockSheet(
                  context,
                  fromInventoryId: widget.product!.inventoryId,
                  productIds: [widget.product!.id!],
                );
                // the form's numbers are stale after a transfer, so go back
                if (ok == true && mounted) Navigator.of(context).pop();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete product',
              onPressed: _handleDelete,
            ),
          ],
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Name
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: _validateRequired,
                ),
                const SizedBox(height: 16),

                // SKU and Category row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skuController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'SKU',
                          prefixIcon: Icon(Icons.qr_code_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCategoryField(categories)),
                  ],
                ),

                // "+ Create new category" reveal field
                if (showNewCategoryField) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoryController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'New category name',
                      hintText: 'e.g. Snacks, Beverages',
                      prefixIcon: Icon(Icons.add_circle_outline),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Pricing section
                Text(
                  'PRICING (USD)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        ],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Cost Price *',
                          prefixText: '\$ ',
                        ),
                        validator: _validateNonNegativeNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sellPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        ],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Sell Price *',
                          prefixText: '\$ ',
                        ),
                        validator: _validateNonNegativeNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stock section
                Text(
                  'STOCK',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Quantity *',
                          prefixIcon: Icon(Icons.inventory_outlined),
                        ),
                        validator: _validateNonNegativeInteger,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lowStockController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Low Stock Threshold',
                          prefixIcon: Icon(Icons.warning_amber_outlined),
                        ),
                        validator: _validateNonNegativeInteger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Save / Update button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSave,
                    icon: Icon(_isEditing ? Icons.save : Icons.add),
                    label: Text(_isEditing ? 'Update Product' : 'Add Product'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
