import 'package:flutter/material.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart' as domain;

class CardEditDialog extends StatefulWidget {
  final domain.Card card;
  final ValueChanged<domain.Card> onSave;

  const CardEditDialog({
    super.key,
    required this.card,
    required this.onSave,
  });

  @override
  State<CardEditDialog> createState() => _CardEditDialogState();
}

class _CardEditDialogState extends State<CardEditDialog> {
  late TextEditingController _translationController;
  late TextEditingController _phoneticController;
  late TextEditingController _exampleController;
  late TextEditingController _exampleTranslationController;
  late TextEditingController _tagsController;
  late int _difficulty;

  @override
  void initState() {
    super.initState();
    _translationController =
        TextEditingController(text: widget.card.translation);
    _phoneticController =
        TextEditingController(text: widget.card.phonetic ?? '');
    _exampleController = TextEditingController(text: widget.card.example ?? '');
    _exampleTranslationController =
        TextEditingController(text: widget.card.exampleTranslation ?? '');
    _tagsController = TextEditingController(text: widget.card.tags.join(', '));
    _difficulty = widget.card.difficulty;
  }

  @override
  void dispose() {
    _translationController.dispose();
    _phoneticController.dispose();
    _exampleController.dispose();
    _exampleTranslationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _save() {
    final tagsText = _tagsController.text.trim();
    final tags = tagsText.isEmpty
        ? <String>[]
        : tagsText.split(',').map((t) => t.trim()).toList();

    final updatedCard = widget.card.copyWith(
      translation: _translationController.text.trim(),
      phonetic: _phoneticController.text.trim().isEmpty
          ? null
          : _phoneticController.text.trim(),
      example: _exampleController.text.trim().isEmpty
          ? null
          : _exampleController.text.trim(),
      exampleTranslation: _exampleTranslationController.text.trim().isEmpty
          ? null
          : _exampleTranslationController.text.trim(),
      tags: tags,
      difficulty: _difficulty,
    );

    widget.onSave(updatedCard);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑卡片'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _translationController,
                decoration: const InputDecoration(
                  labelText: '翻译',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneticController,
                decoration: const InputDecoration(
                  labelText: '音标',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _exampleController,
                decoration: const InputDecoration(
                  labelText: '例句',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _exampleTranslationController,
                decoration: const InputDecoration(
                  labelText: '例句翻译',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: '标签（逗号分隔）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('难度：'),
                  Expanded(
                    child: Slider(
                      value: _difficulty.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _difficulty.toString(),
                      onChanged: (value) {
                        setState(() {
                          _difficulty = value.toInt();
                        });
                      },
                    ),
                  ),
                  Text(
                    _difficulty.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
