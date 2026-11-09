import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';

class Stationery3DModal extends StatefulWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final StationeryTheme theme;
  final String? subtitle;

  const Stationery3DModal({
    super.key,
    required this.title,
    required this.content,
    required this.theme,
    this.subtitle,
    this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required StationeryTheme theme,
    String? subtitle,
    List<Widget>? actions,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Modal',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, anim1, anim2) {
        return Stationery3DModal(
          title: title,
          content: content,
          theme: theme,
          subtitle: subtitle,
          actions: actions,
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curvedValue = Curves.easeOutBack.transform(anim.value);
        final rotationValue = (1.0 - anim.value) * (math.pi / 8);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..scale(curvedValue)
            ..rotateX(rotationValue),
          child: Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<Stationery3DModal> createState() => _Stationery3DModalState();
}

class _Stationery3DModalState extends State<Stationery3DModal> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Main Notebook Card
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
            decoration: widget.theme.doodleCard(
              borderWidth: 3.0,
              borderRadius: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.theme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit_note,
                        color: widget.theme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: widget.theme.fontDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.subtitle != null)
                            Text(
                              widget.subtitle!,
                              style: widget.theme.fontDoodle(
                                fontSize: 13,
                                color: widget.theme.text.withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: widget.theme.text,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: widget.theme.border, thickness: 1.5),
                const SizedBox(height: 8),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: widget.content,
                  ),
                ),

                // Actions
                if (widget.actions != null && widget.actions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: widget.actions!,
                  ),
                ],
              ],
            ),
          ),

          // Top Sticky Tape decoration
          const Positioned(
            top: 6,
            child: StickyTapeWidget(
              width: 90,
              height: 24,
              angle: -0.04,
            ),
          ),
        ],
      ),
    );
  }
}
