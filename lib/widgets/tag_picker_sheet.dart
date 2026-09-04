import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tag.dart';
import '../providers/tag_provider.dart';
import '../theme/app_colors.dart';

/// Maximum number of tags allowed per customer.
const int kMaxTagsPerCustomer = 4;

/// A reusable bottom-sheet picker for attaching tags to a customer.
///
/// Shows the business's tag library (minus already-attached tags),
/// with an inline quick-create field for new tags.
class TagPickerSheet extends ConsumerStatefulWidget {
  final String customerId;
  final List<Tag> currentTags;

  const TagPickerSheet({
    super.key,
    required this.customerId,
    required this.currentTags,
  });

  @override
  ConsumerState<TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends ConsumerState<TagPickerSheet> {
  final _newTagController = TextEditingController();
  bool _isCreating = false;
  String? _errorText;

  Set<String> get _attachedIds => widget.currentTags.map((t) => t.id).toSet();

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  Future<void> _attachTag(Tag tag) async {
    Navigator.of(context).pop();
    try {
      await ref.read(tagActionsProvider).attachTagToCustomer(
            widget.customerId,
            tag.id,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not add tag: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _createAndAttach() async {
    final label = _newTagController.text.trim();
    if (label.isEmpty) {
      setState(() => _errorText = 'Tag name cannot be empty');
      return;
    }

    setState(() {
      _isCreating = true;
      _errorText = null;
    });

    try {
      await ref.read(tagActionsProvider).addAndAttachTag(
            label,
            widget.customerId,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _errorText = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTagsAsync = ref.watch(tagListProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              const Icon(Icons.label_outline_rounded,
                  size: 22, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              Text(
                'Add Tag',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Available tags
          allTagsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Text(
                'Failed to load tags: $err',
                style: const TextStyle(color: AppColors.statusError),
              ),
            ),
            data: (allTags) {
              final available =
                  allTags.where((t) => !_attachedIds.contains(t.id)).toList();

              if (allTags.isEmpty) {
                // Business has no tags at all
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  width: double.infinity,
                  child: const Column(
                    children: [
                      Icon(Icons.label_off_outlined,
                          size: 36, color: AppColors.inactiveGray),
                      SizedBox(height: 8),
                      Text(
                        'No tags yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create your first tag below, or manage tags in Settings',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (available.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  width: double.infinity,
                  child: const Text(
                    'All tags are already attached to this customer',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 6,
                children: available.map((tag) {
                  return ActionChip(
                    label: Text(tag.label),
                    avatar: const Icon(Icons.add, size: 16),
                    onPressed: () => _attachTag(tag),
                    backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.06),
                    labelStyle: const TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: AppColors.primaryPurple.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Quick-create new tag
          Text(
            'Or create a new tag',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newTagController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isCreating,
                  decoration: InputDecoration(
                    hintText: 'e.g. VIP, Wholesale…',
                    errorText: _errorText,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _createAndAttach(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createAndAttach,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create & Add',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
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
