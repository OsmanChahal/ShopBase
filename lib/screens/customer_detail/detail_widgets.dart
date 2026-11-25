part of '../customer_detail_screen.dart';

// ── WhatsApp Button ───────────────────────────────────────────────────────────

class _WhatsAppButton extends StatelessWidget {
  final String phone;

  const _WhatsAppButton({required this.phone});

  /// Strips all non-digit characters for wa.me (international format, no +/spaces).
  String get _waPhone => digitsOnly(phone);

  Future<void> _openWhatsApp(BuildContext context) async {
    final digits = _waPhone;
    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid phone number on file')),
      );
      return;
    }

    final uri = buildWhatsAppUri(digits);
    try {
      final launched = await launchWhatsApp(uri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(whatsAppLaunchFailedMessage)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(whatsAppLaunchFailedMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _openWhatsApp(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366), // WhatsApp green
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      icon: SvgPicture.asset(
        'asset/whatsapp-color-svgrepo-com.svg',
        width: 18,
        height: 18,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
      label: const Text(
        'WhatsApp',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── History Period Filter ─────────────────────────────────────────────────────

class _HistoryPeriodFilter extends StatelessWidget {
  final HistoryPeriod selected;
  final DateTimeRange? customRange;
  final void Function(HistoryPeriod) onChanged;

  static const _labels = {
    HistoryPeriod.allTime: 'All Time',
    HistoryPeriod.thisWeek: 'This Week',
    HistoryPeriod.thisMonth: 'This Month',
    HistoryPeriod.lastMonth: 'Last Month',
    HistoryPeriod.custom: 'Custom',
  };

  const _HistoryPeriodFilter({
    required this.selected,
    required this.customRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HistoryPeriod.values.map((period) {
          final isActive = selected == period;
          String label = _labels[period]!;
          // Show date range for custom when selected
          if (period == HistoryPeriod.custom &&
              isActive &&
              customRange != null) {
            final s = customRange!.start;
            final e = customRange!.end;
            label =
                '${s.day}/${s.month} – ${e.day}/${e.month}';
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isActive,
              onSelected: (_) => onChanged(period),
              selectedColor: AppColors.primaryPurple,
              backgroundColor: AppColors.cardSurface,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isActive
                      ? AppColors.primaryPurple
                      : AppColors.borderLight,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Customer Tags Section ─────────────────────────────────────────────────────

class _CustomerTagsSection extends ConsumerWidget {
  final String customerId;

  const _CustomerTagsSection({required this.customerId});

  void _showTagPicker(BuildContext context, List<Tag> currentTags) =>
      showTagPicker(context, customerId: customerId, currentTags: currentTags);

  Future<void> _removeTag(
      BuildContext context, WidgetRef ref, Tag tag) async {
    try {
      await ref
          .read(tagActionsProvider)
          .detachTagFromCustomer(customerId, tag.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not remove tag: ${errorText(e)}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(customerTagsProvider(customerId));

    return tagsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (tags) {
        final atMax = tags.length >= kMaxTagsPerCustomer;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                'TAGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Existing tag chips
                ...tags.map((tag) => Chip(
                      label: Text(tag.label),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primaryPurple,
                      ),
                      backgroundColor:
                          AppColors.primaryPurple.withValues(alpha: 0.06),
                      side: BorderSide(
                        color:
                            AppColors.primaryPurple.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      deleteIconColor: AppColors.primaryPurple,
                      onDeleted: () => _removeTag(context, ref, tag),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    )),

                // Add tag button (or max message)
                if (atMax)
                  Chip(
                    label: const Text('Max 4 tags'),
                    avatar: const Icon(Icons.info_outline,
                        size: 14, color: AppColors.textSecondary),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: AppColors.borderLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  )
                else
                  ActionChip(
                    label: const Text('Add Tag'),
                    avatar: const Icon(Icons.add,
                        size: 16, color: AppColors.primaryPurple),
                    onPressed: () => _showTagPicker(context, tags),
                    backgroundColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: AppColors.primaryPurple.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
