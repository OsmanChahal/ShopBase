part of '../cart_panel.dart';

// ── Inline Customer Tags (checkout flow, online-only) ─────────────────────────

class _InlineCustomerTags extends ConsumerWidget {
  final String customerId;
  final ThemeData theme;

  const _InlineCustomerTags({
    required this.customerId,
    required this.theme,
  });

  void _showTagPicker(BuildContext context, List<Tag> currentTags) =>
      showTagPicker(context, customerId: customerId, currentTags: currentTags);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Defense-in-depth: if device is offline, hide tags immediately
    final isOnline = ref.watch(isOnlineProvider);
    if (!isOnline) {
      return const SizedBox.shrink();
    }

    final tagsAsync = ref.watch(customerTagsProvider(customerId));

    return tagsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 6),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (tags) {
        final atMax = tags.length >= kMaxTagsPerCustomer;

        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              // Existing tags
              ...tags.map((tag) => Chip(
                    label: Text(tag.label),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.06),
                    side: BorderSide(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    deleteIconColor: theme.colorScheme.primary,
                    onDeleted: () async {
                      try {
                        await ref
                            .read(tagActionsProvider)
                            .detachTagFromCustomer(customerId, tag.id);
                      } catch (_) {}
                    },
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )),

              // Add tag / max reached
              if (atMax)
                Chip(
                  label: const Text('Max $kMaxTagsPerCustomer'),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4),
                  ),
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )
              else
                ActionChip(
                  label: const Text('+ Tag'),
                  onPressed: () => _showTagPicker(context, tags),
                  labelStyle: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        );
      },
    );
  }
}
