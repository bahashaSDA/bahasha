import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/contribution_category.dart';

/// Bottom sheet for entering the amount for a category. Kept minimal and fluid:
/// a big amount field, quick-pick chips, and a confirm — no page navigation, in
/// keeping with the "never feel like changing pages" requirement.
///
/// Returns the entered whole-shilling amount, or null if dismissed.
class AmountSheet extends StatefulWidget {
  const AmountSheet({super.key, required this.category, this.initial = 0});

  final ContributionCategory category;
  final int initial;

  static Future<int?> show(
    BuildContext context, {
    required ContributionCategory category,
    int initial = 0,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AmountSheet(category: category, initial: initial),
    );
  }

  @override
  State<AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<AmountSheet> {
  late final TextEditingController _controller;
  late final bool _fixed;

  @override
  void initState() {
    super.initState();
    _fixed = widget.category.fixedAmount != null;
    final start = _fixed
        ? widget.category.fixedAmount!.toInt()
        : (widget.initial > 0 ? widget.initial : 0);
    _controller = TextEditingController(text: start > 0 ? '$start' : '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_controller.text.trim()) ?? 0;

  void _confirm() => Navigator.of(context).pop(_value > 0 ? _value : null);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.panelGradientBottom,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.category.name, style: AppTypography.title.copyWith(fontSize: 24)),
            const SizedBox(height: 6),
            Text(widget.category.description, style: AppTypography.description),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text('KSh', style: AppTypography.rowLabel.copyWith(color: AppColors.inkMuted)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: !_fixed,
                    enabled: !_fixed,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: AppTypography.title.copyWith(color: AppColors.inkMuted),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    onSubmitted: (_) => _confirm(),
                  ),
                ),
              ],
            ),
            if (!_fixed) ...<Widget>[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <int>[100, 200, 500, 1000, 2000].map(_quickChip).toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _value > 0 ? _confirm : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.indigo,
                  foregroundColor: AppColors.onIndigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Confirm', style: AppTypography.action.copyWith(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(int value) {
    return ActionChip(
      label: Text('$value', style: AppTypography.rowLabel.copyWith(fontSize: 16)),
      backgroundColor: AppColors.panelGreen,
      side: BorderSide.none,
      onPressed: () => setState(() => _controller.text = '$value'),
    );
  }
}
