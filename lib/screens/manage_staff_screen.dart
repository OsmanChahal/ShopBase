import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/staff_provider.dart';
import '../theme/app_colors.dart';


class ManageStaffScreen extends ConsumerWidget {
  const ManageStaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(staffInvitationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Staff'),
      ),
      body: invitationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load staff list',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(staffInvitationsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (invitations) {
          if (invitations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.inactiveGray,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No staff invited yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _openAddStaffFlow(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Staff'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invitations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final inv = invitations[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: AppColors.primaryPurple),
                  ),
                  title: Text(
                    inv.staffFullName ?? inv.email,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: inv.staffFullName != null ? Text(inv.email) : null,
                  trailing: _buildStatusBadge(inv.status),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: invitationsAsync.maybeWhen(
        data: (invs) => invs.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _openAddStaffFlow(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Add Staff'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label = status.toUpperCase();

    switch (status) {
      case 'invited':
      case 'awaiting_approval':
        bgColor = AppColors.warningOrangeBg;
        textColor = AppColors.warningOrange;
        if (status == 'awaiting_approval') label = 'AWAITING APPROVAL';
        break;
      case 'accepted':
      case 'active':
        bgColor = AppColors.statusSuccessBg;
        textColor = AppColors.statusSuccess;
        break;
      case 'declined':
      case 'inactive':
        bgColor = AppColors.statusErrorBg;
        textColor = AppColors.statusError;
        break;
      default:
        bgColor = AppColors.borderGray;
        textColor = AppColors.textGray;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  void _openAddStaffFlow(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _AddStaffFlowScreen()),
    );
  }
}

class _AddStaffFlowScreen extends ConsumerStatefulWidget {
  const _AddStaffFlowScreen();

  @override
  ConsumerState<_AddStaffFlowScreen> createState() => _AddStaffFlowScreenState();
}

class _AddStaffFlowScreenState extends ConsumerState<_AddStaffFlowScreen> {
  int _currentStep = 0;
  
  // Step 1: Email
  final _emailController = TextEditingController();
  bool _isCheckingEmail = false;
  String? _emailError;

  // Step 2: Permissions
  final Map<String, bool> _permissions = {
    'view_dashboard': false,
    'view_crm_overview': false,
    'manage_customers': false,
    'view_inventory': false,
    'edit_inventory': false,
    'use_pos': false,
    'manage_expenses': false,
  };

  final Map<String, String> _permissionLabels = {
    'view_dashboard': 'View Dashboard',
    'view_crm_overview': 'View CRM Overview',
    'manage_customers': 'Manage Customers (View/Edit profiles, tags, WhatsApp)',
    'view_inventory': 'View Inventory',
    'edit_inventory': 'Edit Inventory (Add/Edit/Delete products, adjust stock)',
    'use_pos': 'Use POS (Make sales/checkout)',
    'manage_expenses': 'Manage Expenses',
  };

  // Step 3: Finish
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  Future<void> _handleNextFromEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter an email address');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      return;
    }

    final business = ref.read(currentBusinessProvider);
    if (business == null) return;

    setState(() {
      _isCheckingEmail = true;
      _emailError = null;
    });

    try {
      final isDuplicate = await ref
          .read(staffServiceProvider)
          .checkDuplicateInvitation(business.id, email);

      if (isDuplicate) {
        setState(() {
          _emailError = 'This email already has a pending or accepted invitation.';
        });
      } else {
        setState(() => _currentStep = 1);
      }
    } catch (e) {
      setState(() {
        _emailError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isCheckingEmail = false);
    }
  }

  Future<void> _handleSubmit() async {
    final business = ref.read(currentBusinessProvider);
    if (business == null) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(staffServiceProvider).createInvitation(
            businessId: business.id,
            email: _emailController.text.trim(),
            permissions: _permissions,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to ${_emailController.text.trim()}'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
        ref.invalidate(staffInvitationsProvider);
        Navigator.of(context).pop(); // Go back to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Staff'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildEmailStep(),
                  _buildPermissionsStep(),
                  _buildReviewStep(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who are you inviting?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the email address they will use to sign in.',
            style: TextStyle(color: AppColors.textGray),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'e.g. employee@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              errorText: _emailError,
            ),
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
            onSubmitted: (_) => _handleNextFromEmail(),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            'Set Permissions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Choose what this staff member can access.',
            style: TextStyle(color: AppColors.textGray),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _permissions.keys.map((key) {
              return CheckboxListTile(
                title: Text(_permissionLabels[key]!),
                value: _permissions[key],
                activeColor: AppColors.primaryPurple,
                onChanged: (val) {
                  setState(() => _permissions[key] = val ?? false);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final checkedCount = _permissions.values.where((v) => v).length;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Invitation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Email', style: TextStyle(color: AppColors.textGray)),
                  const SizedBox(height: 4),
                  Text(
                    _emailController.text.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const Divider(height: 32),
                  const Text('Permissions', style: TextStyle(color: AppColors.textGray)),
                  const SizedBox(height: 4),
                  Text(
                    '$checkedCount permissions granted',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() => _currentStep--),
              child: const Text('Back'),
            )
          else
            const SizedBox.shrink(), // Spacer
            
          if (_currentStep == 0)
            ElevatedButton(
              onPressed: _isCheckingEmail ? null : _handleNextFromEmail,
              child: _isCheckingEmail
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Next'),
            )
          else if (_currentStep == 1)
            ElevatedButton(
              onPressed: () => setState(() => _currentStep = 2),
              child: const Text('Next'),
            )
          else
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Finish'),
            ),
        ],
      ),
    );
  }
}
