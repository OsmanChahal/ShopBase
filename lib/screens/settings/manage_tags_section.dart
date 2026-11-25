part of '../settings_sheet.dart';

// ── Manage Tags Section ───────────────────────────────────────────────────────

class _ManageTagsSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ManageTagsSection> createState() => _ManageTagsSectionState();
}

class _ManageTagsSectionState extends ConsumerState<_ManageTagsSection> {
  final _tagController = TextEditingController();
  bool _isAdding = false;
  String? _tagError;

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _addTag() async {
    final label = _tagController.text.trim();
    if (label.isEmpty) {
      setState(() => _tagError = 'Tag name cannot be empty');
      return;
    }

    setState(() {
      _isAdding = true;
      _tagError = null;
    });

    try {
      await ref.read(tagActionsProvider).addTag(label);
      _tagController.clear();
    } catch (e) {
      if (mounted) {
        setState(() {
          _tagError = errorText(e);
        });
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _confirmDeleteTag(Tag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Tag'),
        content: Text(
          'Delete "${tag.label}"? It will be removed from all customers who have it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.statusError),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(tagActionsProvider).deleteTag(tag.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${tag.label}" tag deleted'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete: ${errorText(e)}',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagsAsync = ref.watch(tagListProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.baseWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.label_outline_rounded,
                size: 20,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(width: 8),
              Text(
                'Tag Library',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tag list
          tagsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Text(
              'Failed to load tags: $err',
              style: const TextStyle(
                color: AppColors.statusError,
                fontSize: 13,
              ),
            ),
            data: (tags) {
              if (tags.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.label_off_outlined,
                        size: 18,
                        color: AppColors.inactiveGray,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'No tags yet — add your first one',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tags.map((tag) {
                  return Chip(
                    label: Text(tag.label),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.primaryPurple,
                    ),
                    backgroundColor: AppColors.primaryPurple.withValues(
                      alpha: 0.06,
                    ),
                    side: BorderSide(
                      color: AppColors.primaryPurple.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    deleteIconColor: AppColors.primaryPurple,
                    onDeleted: () => _confirmDeleteTag(tag),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Add new tag
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isAdding,
                  decoration: InputDecoration(
                    hintText: 'New tag name…',
                    errorText: _tagError,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _isAdding ? null : _addTag,
                  icon: _isAdding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
