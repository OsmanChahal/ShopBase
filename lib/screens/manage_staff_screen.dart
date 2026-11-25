import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business_member.dart';
import '../providers/auth_provider.dart';
import '../providers/staff_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/inventory_access_widgets.dart';
import '../utils/error_text.dart';
import '../constants/permissions.dart';

part 'manage_staff/edit_staff_member_sheet.dart';
part 'manage_staff/add_staff_flow_screen.dart';

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
          .read(staffServiceProvider)
          .respondToInvitation(invitationId: invitationId, status: 'accepted');
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
          .read(staffServiceProvider)
          .respondToInvitation(invitationId: invitationId, status: 'declined');
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
