import 'package:flutter/material.dart';
import 'package:enstudy/core/theme/colors.dart';

class CardPreviewItem extends StatefulWidget {
  final String cardId;
  final String content;
  final String translation;
  final String phonetic;
  final String example;
  final String exampleTranslation;
  final bool isSelected;
  final bool isRecommendation;
  final String? reason;
  final String? type;
  final VoidCallback onToggle;
  final void Function(
    String? content,
    String? translation,
    String? phonetic,
    String? example,
    String? exampleTranslation,
  ) onEdit;

  const CardPreviewItem({
    super.key,
    required this.cardId,
    required this.content,
    required this.translation,
    required this.phonetic,
    required this.example,
    required this.exampleTranslation,
    required this.isSelected,
    required this.isRecommendation,
    this.reason,
    this.type,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  State<CardPreviewItem> createState() => _CardPreviewItemState();
}

class _CardPreviewItemState extends State<CardPreviewItem> {
  bool _isExpanded = false;
  bool _isEditing = false;

  late TextEditingController _contentController;
  late TextEditingController _translationController;
  late TextEditingController _phoneticController;
  late TextEditingController _exampleController;
  late TextEditingController _exampleTranslationController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.content);
    _translationController = TextEditingController(text: widget.translation);
    _phoneticController = TextEditingController(text: widget.phonetic);
    _exampleController = TextEditingController(text: widget.example);
    _exampleTranslationController =
        TextEditingController(text: widget.exampleTranslation);
  }

  @override
  void didUpdateWidget(covariant CardPreviewItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _contentController.text = widget.content;
    }
    if (oldWidget.translation != widget.translation) {
      _translationController.text = widget.translation;
    }
    if (oldWidget.phonetic != widget.phonetic) {
      _phoneticController.text = widget.phonetic;
    }
    if (oldWidget.example != widget.example) {
      _exampleController.text = widget.example;
    }
    if (oldWidget.exampleTranslation != widget.exampleTranslation) {
      _exampleTranslationController.text = widget.exampleTranslation;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _translationController.dispose();
    _phoneticController.dispose();
    _exampleController.dispose();
    _exampleTranslationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        widget.isRecommendation ? AppColors.accent : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? accentColor.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? accentColor.withValues(alpha: 0.3)
                : AppColors.divider,
            width: widget.isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildCheckbox(accentColor),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMainContent(context)),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.expand_more,
                        size: 20,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded) _buildExpandedContent(context, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(Color accentColor) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isSelected ? accentColor : Colors.transparent,
          border: Border.all(
            color: widget.isSelected ? accentColor : AppColors.textHint,
            width: 2,
          ),
        ),
        child: widget.isSelected
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.content,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.type != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.type!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          widget.translation,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.phonetic.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            widget.phonetic,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(46, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (widget.reason != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.reason!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.accent,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_isEditing) ...[
            _buildEditField('内容', _contentController),
            const SizedBox(height: 6),
            _buildEditField('翻译', _translationController),
            const SizedBox(height: 6),
            _buildEditField('音标', _phoneticController),
            const SizedBox(height: 6),
            _buildEditField('例句', _exampleController),
            const SizedBox(height: 6),
            _buildEditField('例句翻译', _exampleTranslationController),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveEdit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                  ),
                  child: const Text('保存'),
                ),
              ],
            ),
          ] else ...[
            if (widget.example.isNotEmpty) ...[
              Text(
                '例句',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.example,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (widget.exampleTranslation.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.exampleTranslation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('编辑'),
                style: TextButton.styleFrom(
                  foregroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  void _saveEdit() {
    widget.onEdit(
      _contentController.text,
      _translationController.text,
      _phoneticController.text,
      _exampleController.text,
      _exampleTranslationController.text,
    );
    setState(() => _isEditing = false);
  }
}
