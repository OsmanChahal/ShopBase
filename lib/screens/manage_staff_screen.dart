import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business_member.dart';
import '../providers/auth_provider.dart';
import '../providers/staff_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/inventory_access_widgets.dart';

class ManageStaffScreen extends ConsumerStatefulWidget {
  const ManageStaffScreen({super.key});

  @override
  ConsumerState<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends ConsumerState<ManageStaffScreen>
    with SingleTickerProviderStateMixin {
  RealtimeChannel? _requestsChannel;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToRequests();
    });
  }

  void _subscribeToRequests() {
    try {
      final business = ref.read(currentBusinessProvider);
      if (business != null) {
        _requestsChannel = ref
            .read(staffServiceProvider)
            .subscribeToStaffRequests(business.id, () {
              if (mounted) {
                ref.invalidate(staffInvitationsProvider);
                ref.invalidate(staffMembersProvider);
              }
            });
      }
    } catch (_) {
      // Subscription failure is non-fatal; the lists still load normally.
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_requestsChannel != null) {
      ref
          .read(staffServiceProvider)
          .unsubscribeFromStaffRequests(_requestsChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invitationsAsync = ref.watch(staffInvitationsProvider);
    final membersAsync = ref.watch(staffMembersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Staff'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Staff Members'),
            Tab(text: 'Invitations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Staff Members ──
          membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    const Text('Failed to load staff members'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(staffMembersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (members) {
              if (members.isEmpty) {
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
                        'No active staff members',
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
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isInactive = member.status == 'inactive';

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isInactive
                            ? AppColors.borderGray
                            : AppColors.primaryPurple.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          color: isInactive
                              ? AppColors.textGray
                              : AppColors.primaryPurple,
                        ),
                      ),
                      title: Text(
                        member.displayName ?? 'Staff Member',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isInactive
                              ? AppColors.textGray
                              : AppColors.accentDark,
                        ),
                      ),
                      subtitle: Text(
                        '${member.permissions.values.where((v) => v).length} permissions • ${member.status}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusBadge(member.status),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textGray,
                          ),
                        ],
                      ),
                      onTap: () => _openEditMemberSheet(context, member),
                    ),
                  );
                },
              );
            },
          ),

          // ── Tab 2: Invitations ──
          invitationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    const Text('Failed to load invitations'),
                    const SizedBox(height: 16),
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
                        Icons.mail_outline,
                        size: 64,
                        color: AppColors.inactiveGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No staff invitations',
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final inv = invitations[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryPurple.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      title: Text(
                        inv.staffFullName ?? inv.email,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: inv.staffFullName != null
                          ? Text(inv.email)
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (inv.status == 'awaiting_approval') ...[
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.statusError,
                              ),
                              tooltip: 'Decline',
                              onPressed: () => _handleDecline(context, inv.id),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: AppColors.statusSuccess,
                              ),
                              tooltip: 'Accept',
                              onPressed: () => _handleAccept(context, inv.id),
                            ),
                          ],
                          if (inv.status == 'invited' ||
                              inv.status == 'awaiting_approval') ...[
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.textGray,
                              ),
                              tooltip: 'Cancel Invitation',
                              onPressed: () =>
                                  _handleCancelInvitation(context, inv.id),
                            ),
                          ],
                          _buildStatusBadge(inv.status),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddStaffFlow(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _AddStaffFlowScreen()));
  }

  void _openEditMemberSheet(BuildContext context, BusinessMember member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditStaffMemberSheet(member: member),
    );
  }

  Future<void> _handleAccept(BuildContext context, String invitationId) async {
    try {
      await ref
          .read(supabaseClientProvider)
          .from('staff_invitations')
          .update({'status': 'accepted'})
          .eq('id', invitationId);
      await ref
          .read(staffServiceProvider)
          .broadcastStatusUpdate(
            invitationId: invitationId,
            status: 'accepted',
          );
      ref.invalidate(staffInvitationsProvider);
      ref.invalidate(staffMembersProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept: $e'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    }
  }

  Future<void> _handleDecline(BuildContext context, String invitationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Request?'),
        content: const Text(
          'Are you sure you want to decline this staff member?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Decline',
              style: TextStyle(color: AppColors.statusError),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref
          .read(supabaseClientProvider)
          .from('staff_invitations')
          .update({'status': 'declined'})
          .eq('id', invitationId);
      await ref
          .read(staffServiceProvider)
          .broadcastStatusUpdate(
            invitationId: invitationId,
            status: 'declined',
          );
      ref.invalidate(staffInvitationsProvider);
      ref.invalidate(staffMembersProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline: $e'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    }
  }

  Future<void> _handleCancelInvitation(
    BuildContext context,
    String invitationId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Invitation?'),
        content: const Text('Are you sure you want to cancel this invitation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cancel Invite',
              style: TextStyle(color: AppColors.statusError),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(staffServiceProvider).cancelInvitation(invitationId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation cancelled.'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
      ref.invalidate(staffInvitationsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    }
  }
}

class _EditStaffMemberSheet extends ConsumerStatefulWidget {
  final BusinessMember member;
  const _EditStaffMemberSheet({required this.member});

  @override
  ConsumerState<_EditStaffMemberSheet> createState() =>
      _EditStaffMemberSheetState();
}

class _EditStaffMemberSheetState extends ConsumerState<_EditStaffMemberSheet> {
  late Map<String, bool> _permissions;
  bool _isSaving = false;

  final Map<String, String> _permissionLabels = {
    'view_dashboard': 'View Dashboard',
    'view_crm_overview': 'View CRM Overview',
    'manage_customers': 'Manage Customers',
    'view_inventory': 'View Inventory',
    'edit_inventory': 'Edit Inventory',
    'use_pos': 'Use POS',
    'manage_expenses': 'Manage Expenses',
  };

  @override
  void initState() {
    super.initState();
    _permissions = Map<String, bool>.from(widget.member.permissions);
    for (final key in _permissionLabels.keys) {
      _permissions.putIfAbsent(key, () => false);
    }
  }

  Future<void> _savePermissions() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(staffServiceProvider)
          .updateMemberPermissions(widget.member.id, _permissions);
      ref.invalidate(staffMembersProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions updated successfully.'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleStatus() async {
    final newStatus = widget.member.status == 'active' ? 'inactive' : 'active';
    final actionName = newStatus == 'inactive' ? 'Deactivate' : 'Reactivate';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionName Staff Member?'),
        content: Text(
          'Are you sure you want to $actionName this staff member?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              actionName,
              style: TextStyle(
                color: newStatus == 'inactive'
                    ? AppColors.statusError
                    : AppColors.statusSuccess,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(staffServiceProvider)
          .updateMemberStatus(widget.member.id, newStatus);
      ref.invalidate(staffMembersProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff member is now $newStatus.'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInactive = widget.member.status == 'inactive';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.baseWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.member.displayName ?? 'Staff Member',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isInactive
                        ? AppColors.statusErrorBg
                        : AppColors.statusSuccessBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.member.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isInactive
                          ? AppColors.statusError
                          : AppColors.statusSuccess,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Edit Permissions',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGray,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ..._permissionLabels.keys.map((key) {
                  return CheckboxListTile(
                    title: Text(_permissionLabels[key]!),
                    value: _permissions[key] ?? false,
                    activeColor: AppColors.primaryPurple,
                    onChanged: (val) {
                      setState(() => _permissions[key] = val ?? false);
                    },
                  );
                }),
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    'Location access',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGray,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: StaffLocationAccessSection(member: widget.member),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _toggleStatus,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isInactive
                          ? AppColors.statusSuccess
                          : AppColors.statusError,
                      side: BorderSide(
                        color: isInactive
                            ? AppColors.statusSuccess
                            : AppColors.statusError,
                      ),
                    ),
                    child: Text(isInactive ? 'Reactivate' : 'Deactivate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _savePermissions,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Permissions'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStaffFlowScreen extends ConsumerStatefulWidget {
  const _AddStaffFlowScreen();

  @override
  ConsumerState<_AddStaffFlowScreen> createState() =>
      _AddStaffFlowScreenState();
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
          _emailError =
              'This email already has a pending or accepted invitation.';
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
      await ref
          .read(staffServiceProvider)
          .createInvitation(
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
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
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
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
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
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email',
                    style: TextStyle(color: AppColors.textGray),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _emailController.text.trim(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Permissions',
                    style: TextStyle(color: AppColors.textGray),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$checkedCount permissions granted',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
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
