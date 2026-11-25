part of '../manage_staff_screen.dart';

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

  final Map<String, String> _permissionLabels = Permissions.shortLabels;

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
