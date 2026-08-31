import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

/// A modal bottom sheet for quickly adjusting stock quantity.
class StockAdjustDialog extends ConsumerStatefulWidget {
  final Product product;

  const StockAdjustDialog({super.key, required this.product});

  @override
  ConsumerState<StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends ConsumerState<StockAdjustDialog> {
  late int _delta;
  final _deltaController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _delta = 0;
    _deltaController.text = '0';
  }

  @override
  void dispose() {
    _deltaController.dispose();
    super.dispose();
  }

  void _updateDelta(int newDelta) {
    setState(() {
      _delta = newDelta;
      _deltaController.text = _delta.toString();
    });
  }

  int get _newQuantity => widget.product.quantity + _delta;

  Future<void> _handleConfirm() async {
    if (_delta == 0) {
      Navigator.of(context).pop();
      return;
    }

    if (_newQuantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Stock cannot go below zero'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(productActionsProvider)
          .adjustStock(widget.product.id!, _delta);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock updated: ${widget.product.quantity} → $_newQuantity',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = _newQuantity >= 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Adjust Stock',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.product.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),

          // Current stock display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StockBadge(
                label: 'Current',
                value: widget.product.quantity.toString(),
                color: theme.colorScheme.secondary,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              _StockBadge(
                label: 'New',
                value: _newQuantity.toString(),
                color: !isValid
                    ? theme.colorScheme.error
                    : _newQuantity <= widget.product.lowStockThreshold
                        ? const Color(0xFFF59E0B) // Amber 500
                        : const Color(0xFF16A34A), // Green 600
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick adjust buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QuickButton(
                label: '-10',
                onTap: () => _updateDelta(_delta - 10),
              ),
              _QuickButton(
                label: '-5',
                onTap: () => _updateDelta(_delta - 5),
              ),
              _QuickButton(
                label: '-1',
                onTap: () => _updateDelta(_delta - 1),
              ),
              const SizedBox(width: 8),
              // Delta input
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _deltaController,
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null) {
                      setState(() => _delta = parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              _QuickButton(
                label: '+1',
                onTap: () => _updateDelta(_delta + 1),
              ),
              _QuickButton(
                label: '+5',
                onTap: () => _updateDelta(_delta + 5),
              ),
              _QuickButton(
                label: '+10',
                onTap: () => _updateDelta(_delta + 10),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading || !isValid ? null : _handleConfirm,
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _delta == 0
                          ? 'No Change'
                          : 'Confirm (${_delta > 0 ? '+' : ''}$_delta)',
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Cancel
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// A small badge showing a stock value with a colored accent.
class _StockBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StockBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// A quick increment/decrement button.
class _QuickButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNegative = label.startsWith('-');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isNegative
                ? const Color(0xFFFEE2E2) // Red 100
                : const Color(0xFFDCFCE7), // Green 100
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isNegative
                  ? const Color(0xFFDC2626) // Red 600
                  : const Color(0xFF16A34A), // Green 600
            ),
          ),
        ),
      ),
    );
  }
}
