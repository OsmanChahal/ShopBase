import 'package:flutter/material.dart';

class LocDesign {
  static const purple = Color(0xFF582C8A);
  static const purpleDark = Color(0xFF45206D);
  static const purpleLight = Color(0xFFF3EEFA);
  static const green = Color(0xFF10B981);
  static const border = Color(0xFFECEEF2);
  static const fieldBorder = Color(0xFFD8DCE3);
  static const surface = Color(0xFFF8F9FA);
  static const ink = Color(0xFF1E1B2E);
  static const muted = Color(0xFF737380);
  static const danger = Color(0xFFE11D48);

  static const cardShadow = [
    BoxShadow(color: Color(0x0A1B1924), blurRadius: 10, offset: Offset(0, 2)),
  ];
}

/// Wraps a design element whose backend doesn't exist yet: dimmed, inert,
/// with a "Coming soon" tooltip. Search the code for `ComingSoon` to find
/// every placeholder.
class ComingSoon extends StatelessWidget {
  final Widget child;
  final String message;
  const ComingSoon({
    super.key,
    required this.child,
    this.message = 'Coming soon',
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: message,
    child: Opacity(opacity: 0.45, child: IgnorePointer(child: child)),
  );
}

class LocSection extends StatelessWidget {
  final Color dot;
  final String title;
  final Widget? trailing;
  final Widget child;
  const LocSection({
    super.key,
    required this.dot,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: LocDesign.border),
      boxShadow: LocDesign.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF404040),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class LocBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const LocBadge(this.text, {super.key, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
    ),
  );
}

InputDecoration locInput(String hint, {String? error, bool readOnly = false}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    errorText: error,
    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFA3A3AD)),
    filled: true,
    fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: b(LocDesign.fieldBorder),
    enabledBorder: b(LocDesign.fieldBorder),
    disabledBorder: b(LocDesign.fieldBorder),
    focusedBorder: b(LocDesign.purple, 1.5),
    errorBorder: b(LocDesign.danger),
    focusedErrorBorder: b(LocDesign.danger, 1.5),
  );
}

class LocLabel extends StatelessWidget {
  final String text;
  final bool required;
  const LocLabel(this.text, {super.key, this.required = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF404040),
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFF43F5E)),
            ),
        ],
      ),
    ),
  );
}

/// A toggle row that is always inert (used only inside ComingSoon).
class LocToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  const LocToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: LocDesign.muted,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
      Switch(value: value, onChanged: null, activeColor: LocDesign.purple),
    ],
  );
}

class LocPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final bool gradient;
  const LocPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
    this.gradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    return Opacity(
      opacity: enabled || loading ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Ink(
            height: 50,
            decoration: BoxDecoration(
              color: gradient ? null : LocDesign.purple,
              gradient: gradient
                  ? const LinearGradient(
                      colors: [LocDesign.purple, LocDesign.purpleDark],
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x59582C8A),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

AppBar locAppBar(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Color subtitleColor,
  Widget? trailing,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    foregroundColor: LocDesign.ink,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    shape: const Border(bottom: BorderSide(color: LocDesign.border)),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    title: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: LocDesign.ink,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: subtitleColor,
          ),
        ),
      ],
    ),
    actions: [if (trailing != null) trailing, const SizedBox(width: 8)],
  );
}
