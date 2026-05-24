import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:enstudy/core/constants/api_config.dart';
import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/profile/presentation/providers/profile_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _secureStorage = const FlutterSecureStorage();

  late TextEditingController _remindTimeController;
  double _newCardsPerDay = 10;
  String _gameDifficulty = 'auto';

  final _qwenApiKeyController = TextEditingController();
  final _corsProxyUrlController = TextEditingController();

  bool _isLoadingKeys = true;
  bool _hasCustomQwenApiKey = false;
  bool _hasCustomCorsProxyUrl = false;

  @override
  void initState() {
    super.initState();
    _remindTimeController = TextEditingController(text: '08:00');
    _loadSettings();
    _loadApiKeys();
  }

  @override
  void dispose() {
    _remindTimeController.dispose();
    _qwenApiKeyController.dispose();
    _corsProxyUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null && mounted) {
      setState(() {
        _remindTimeController.text = profile.remindTime;
        _newCardsPerDay = profile.newCardsPerDay.toDouble();
      });
    }
  }

  Future<void> _loadApiKeys() async {
    final qwenApiKey = await _secureStorage.read(key: 'qwen_api_key') ?? '';
    final corsProxyUrl = await _secureStorage.read(key: 'cors_proxy_url') ?? '';

    if (mounted) {
      setState(() {
        _hasCustomQwenApiKey = qwenApiKey.isNotEmpty;
        _hasCustomCorsProxyUrl = corsProxyUrl.isNotEmpty;
        _qwenApiKeyController.text = qwenApiKey;
        _corsProxyUrlController.text = corsProxyUrl;
        _isLoadingKeys = false;
      });
    }
  }

  Future<void> _saveApiKeys() async {
    final qwenApiKey = _qwenApiKeyController.text.trim();
    final corsProxyUrl = _corsProxyUrlController.text.trim();

    if (qwenApiKey.isEmpty) {
      await _secureStorage.delete(key: 'qwen_api_key');
    } else {
      await _secureStorage.write(key: 'qwen_api_key', value: qwenApiKey);
    }

    if (corsProxyUrl.isEmpty) {
      await _secureStorage.delete(key: 'cors_proxy_url');
    } else {
      await _secureStorage.write(key: 'cors_proxy_url', value: corsProxyUrl);
    }

    setState(() {
      _hasCustomQwenApiKey = qwenApiKey.isNotEmpty;
      _hasCustomCorsProxyUrl = corsProxyUrl.isNotEmpty;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRemindTimeSection(),
            const SizedBox(height: 20),
            _buildNewCardsSection(),
            const SizedBox(height: 20),
            _buildGameDifficultySection(),
            const SizedBox(height: 20),
            _buildApiKeySection(),
            if (kIsWeb) ...[
              const SizedBox(height: 20),
              _buildCorsProxySection(),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('复习提醒时间',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickTime(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _remindTimeController.text,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textHint, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCardsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_card_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('每日新卡数量',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('5',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  '${_newCardsPerDay.toInt()}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const Text('20',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            Slider(
              value: _newCardsPerDay,
              min: 5,
              max: 20,
              divisions: 15,
              activeColor: AppColors.primary,
              label: '${_newCardsPerDay.toInt()}',
              onChanged: (v) => setState(() => _newCardsPerDay = v),
              onChangeEnd: (v) =>
                  ref.read(profileProvider.notifier).updateSettings(
                        newCardsPerDay: v.toInt(),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameDifficultySection() {
    const difficulties = [
      ('auto', '自动', Icons.auto_mode_outlined),
      ('easy', '简单', Icons.sentiment_satisfied_outlined),
      ('medium', '中等', Icons.sentiment_neutral_outlined),
      ('hard', '困难', Icons.sentiment_very_dissatisfied_outlined),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_esports_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('游戏难度',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: difficulties.map((d) {
                final isSelected = _gameDifficulty == d.$1;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(d.$3,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(d.$2),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  onSelected: (_) {
                    setState(() => _gameDifficulty = d.$1);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeySection() {
    final defaultKey = ApiConfig.qwenApiKey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.key_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('API Key 配置',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '千问多模态模型 API Key，用于图片识别和分析',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: 16),
            if (_isLoadingKeys)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildSecureField(
                label: '千问 API Key',
                controller: _qwenApiKeyController,
                icon: Icons.smart_toy_outlined,
                isCustom: _hasCustomQwenApiKey,
                defaultValue: defaultKey,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _saveApiKeys,
                  child: const Text('保存密钥'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecureField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isCustom,
    required String defaultValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            labelStyle: const TextStyle(fontSize: 13),
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isCustom ? Icons.edit : Icons.check_circle_outline,
              size: 14,
              color: isCustom ? AppColors.accent : AppColors.success,
            ),
            const SizedBox(width: 4),
            Text(
              isCustom
                  ? '使用自定义值'
                  : (defaultValue.isNotEmpty
                      ? '使用默认值 (${defaultValue.substring(0, defaultValue.length > 8 ? 8 : defaultValue.length)}...)'
                      : '未配置默认值'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isCustom ? AppColors.accent : AppColors.success,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCorsProxySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('CORS 代理配置',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Web 版需要通过代理解决浏览器跨域限制',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('替代方案',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '运行时添加参数跳过跨域检查：\n'
                    'flutter run -d chrome \\\n'
                    '  --web-browser-flag=--disable-web-security',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _corsProxyUrlController,
              decoration: InputDecoration(
                labelText: 'CORS 代理地址',
                hintText: '例如: https://cors-proxy.example.com/',
                prefixIcon: const Icon(Icons.swap_horiz,
                    size: 20, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                labelStyle: const TextStyle(fontSize: 13),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _hasCustomCorsProxyUrl
                      ? Icons.edit
                      : Icons.check_circle_outline,
                  size: 14,
                  color: _hasCustomCorsProxyUrl
                      ? AppColors.accent
                      : AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  _hasCustomCorsProxyUrl ? '使用自定义代理' : '未配置代理（直连）',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _hasCustomCorsProxyUrl
                            ? AppColors.accent
                            : AppColors.success,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final parts = _remindTimeController.text.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected))
                  return AppColors.primary;
                return AppColors.primary.withValues(alpha: 0.1);
              }),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _remindTimeController.text = timeStr);
      ref.read(profileProvider.notifier).updateSettings(remindTime: timeStr);
    }
  }
}
