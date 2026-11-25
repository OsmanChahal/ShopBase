part of '../cart_panel.dart';

/// Connect with Customer section for POS sales — extended with inline tag management.
class _CustomerPickerSection extends ConsumerWidget {
  final ThemeData theme;

  const _CustomerPickerSection({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedName = ref.watch(selectedCustomerNameProvider);
    final selectedId = ref.watch(selectedCustomerIdProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selectedId != null
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                'Connect with Customer (Optional)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedId != null && selectedName != null) ...[
            Row(
              children: [
                Expanded(
                  child: Chip(
                    label: Text(selectedName),
                    avatar: CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        selectedName.isNotEmpty
                            ? selectedName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      ref.read(selectedCustomerIdProvider.notifier).state =
                          null;
                      ref.read(selectedCustomerNameProvider.notifier).state =
                          null;
                    },
                  ),
                ),
                TextButton(
                  onPressed: () => _showCustomerPicker(context, ref),
                  child: const Text('Change'),
                ),
              ],
            ),
            // ── Inline tag management for the selected customer (online-only) ──
            if (ref.watch(isOnlineProvider))
              _InlineCustomerTags(
                customerId: selectedId,
                theme: theme,
              ),
          ] else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCustomerPicker(context, ref),
                icon: const Icon(Icons.person_search, size: 18),
                label: const Text('Connect Customer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCustomerPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _CustomerSearchSheet(
          onSelect: (customer) {
            ref.read(selectedCustomerIdProvider.notifier).state = customer.id;
            ref.read(selectedCustomerNameProvider.notifier).state =
                customer.name;
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }
}

/// Bottom sheet for searching and selecting a customer, with an inline "Add New Customer" button.
class _CustomerSearchSheet extends ConsumerStatefulWidget {
  final void Function(Customer) onSelect;

  const _CustomerSearchSheet({
    required this.onSelect,
  });

  @override
  ConsumerState<_CustomerSearchSheet> createState() =>
      _CustomerSearchSheetState();
}

class _CustomerSearchSheetState
    extends ConsumerState<_CustomerSearchSheet> {
  String _query = '';

  /// Lightweight inline customer creation for POS — writes to local DB + enqueues.
  void _showInlineCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _InlineCustomerDialog(
        onCreated: (customer) {
          if (mounted) widget.onSelect(customer);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customersAsync = ref.watch(customerListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Customer',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showInlineCustomerDialog(context),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Add New'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                onChanged: (val) => setState(() => _query = val),
                decoration: const InputDecoration(
                  hintText: 'Search by name...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: customersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text('Failed to load customers: $err'),
                  ),
                  data: (customers) {
                    final filtered = _query.isEmpty
                        ? customers
                        : customers
                            .where((c) => c.name
                                .toLowerCase()
                                .contains(_query.toLowerCase()))
                            .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No customers found',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _showInlineCustomerDialog(context),
                              icon: const Icon(Icons.person_add, size: 18),
                              label: const Text('Create New Customer'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            child: Text(
                              c.name.isNotEmpty
                                  ? c.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text(c.name),
                          subtitle: c.phone != null && c.phone!.isNotEmpty
                              ? Text(c.phone!)
                              : null,
                          onTap: () => widget.onSelect(c),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Add Customer" dialog used from the POS customer search. Owns its text
/// controllers, and saves the phone in the same international format as
/// [CustomerFormScreen] (via [IntlPhoneField], defaulting to Lebanon).
class _InlineCustomerDialog extends ConsumerStatefulWidget {
  final void Function(Customer) onCreated;

  const _InlineCustomerDialog({required this.onCreated});

  @override
  ConsumerState<_InlineCustomerDialog> createState() =>
      _InlineCustomerDialogState();
}

class _InlineCustomerDialogState extends ConsumerState<_InlineCustomerDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  /// Full international number (e.g. "+96170123456"), or null when no
  /// digits have been entered.
  String? _completePhoneNumber;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final business = ref.read(currentBusinessProvider);
    if (business == null) return;

    try {
      final customer = await ref.read(customerActionsProvider).addCustomer(
            businessId: business.id,
            name: name,
            phone: _completePhoneNumber,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreated(customer);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorText(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Customer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name *',
              prefixIcon: Icon(Icons.person_outline),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          IntlPhoneField(
            controller: _phoneController,
            initialCountryCode: 'LB',
            decoration: const InputDecoration(
              labelText: 'Phone (optional)',
            ),
            invalidNumberMessage: 'Enter a valid phone number',
            onChanged: (phone) {
              _completePhoneNumber =
                  phone.number.trim().isEmpty ? null : phone.completeNumber;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _add,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
