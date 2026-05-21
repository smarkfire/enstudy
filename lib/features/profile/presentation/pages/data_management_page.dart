import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/core/database/daos/card_dao.dart';
import 'package:enstudy/core/database/daos/source_dao.dart';
import 'package:enstudy/core/database/daos/game_session_dao.dart';
import 'package:enstudy/core/database/daos/review_log_dao.dart';
import 'package:enstudy/core/database/daos/user_profile_dao.dart';
import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/profile/data/datasources/data_transfer_service.dart';
import 'package:enstudy/features/upload/presentation/providers/upload_provider.dart';

final dataTransferServiceProvider = Provider<DataTransferService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DataTransferService(
    db,
    CardDao(db),
    SourceDao(db),
    GameSessionDao(db),
    ReviewLogDao(db),
    UserProfileDao(db),
  );
});

class DataManagementPage extends ConsumerStatefulWidget {
  const DataManagementPage({super.key});

  @override
  ConsumerState<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends ConsumerState<DataManagementPage> {
  bool _exportCards = true;
  bool _exportReviewLogs = true;
  bool _exportGameSessions = true;
  bool _exportProfile = true;
  bool _includeImages = false;

  String? _importFilePath;
  ImportPreview? _importPreview;
  ConflictStrategy _conflictStrategy = ConflictStrategy.keepNewer;

  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据管理')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExportSection(),
            const SizedBox(height: 24),
            _buildImportSection(),
            const SizedBox(height: 24),
            _buildBackupHistory(),
            const SizedBox(height: 24),
            _buildBottomTip(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('导出数据', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildCheckboxTile('卡片数据', _exportCards, (v) => setState(() => _exportCards = v)),
            _buildCheckboxTile('复习记录', _exportReviewLogs, (v) => setState(() => _exportReviewLogs = v)),
            _buildCheckboxTile('游戏记录', _exportGameSessions, (v) => setState(() => _exportGameSessions = v)),
            _buildCheckboxTile('个人设置', _exportProfile, (v) => setState(() => _exportProfile = v)),
            const Divider(height: 24),
            SwitchListTile(
              dense: true,
              title: const Text('包含图片', style: TextStyle(fontSize: 14)),
              subtitle: Text('导出图片会增加文件大小', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              value: _includeImages,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _includeImages = v),
            ),
            const SizedBox(height: 8),
            Text(
              '预计大小：${_estimateSize()}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _canExport() && !_isExporting ? _handleExport : null,
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.share_outlined, size: 18),
                label: Text(_isExporting ? '导出中...' : '导出并分享'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('导入数据', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _handlePickFile,
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: Text(_importFilePath != null ? '已选择文件' : '选择文件'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            if (_importPreview != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('导入预览', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    _buildPreviewRow('卡片', '${_importPreview!.cardCount} 条'),
                    _buildPreviewRow('来源', '${_importPreview!.sourceCount} 条'),
                    _buildPreviewRow('复习记录', '${_importPreview!.reviewLogCount} 条'),
                    _buildPreviewRow('游戏记录', '${_importPreview!.gameSessionCount} 条'),
                    _buildPreviewRow('版本', _importPreview!.version),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('冲突处理策略', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              ...ConflictStrategy.values.map((strategy) => RadioListTile<ConflictStrategy>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_getStrategyLabel(strategy), style: const TextStyle(fontSize: 13)),
                    subtitle: Text(_getStrategyDesc(strategy), style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: strategy,
                    groupValue: _conflictStrategy,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _conflictStrategy = v!),
                  )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: !_isImporting ? _handleImport : null,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download_done_outlined, size: 18),
                  label: Text(_isImporting ? '导入中...' : '确认导入'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackupHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('最近备份', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '暂无备份记录',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.textHint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '导入将合并数据，不会删除已有内容',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile(String title, bool value, ValueChanged<bool> onChanged) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (v) => onChanged(v ?? false),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _getStrategyLabel(ConflictStrategy strategy) {
    switch (strategy) {
      case ConflictStrategy.keepNewer:
        return '保留较新';
      case ConflictStrategy.overwrite:
        return '覆盖已有';
      case ConflictStrategy.skip:
        return '跳过冲突';
    }
  }

  String _getStrategyDesc(ConflictStrategy strategy) {
    switch (strategy) {
      case ConflictStrategy.keepNewer:
        return '比较时间戳，保留较新的数据';
      case ConflictStrategy.overwrite:
        return '用导入数据覆盖已有数据';
      case ConflictStrategy.skip:
        return '跳过冲突数据，保留已有数据';
    }
  }

  bool _canExport() {
    return _exportCards || _exportReviewLogs || _exportGameSessions || _exportProfile;
  }

  String _estimateSize() {
    int estimate = 0;
    if (_exportCards) estimate += 50;
    if (_exportReviewLogs) estimate += 30;
    if (_exportGameSessions) estimate += 20;
    if (_exportProfile) estimate += 5;
    if (_includeImages) estimate += 500;
    return '~${estimate}KB';
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final service = ref.read(dataTransferServiceProvider);
      final file = await service.exportData(includeImages: _includeImages);
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'EnStudy 数据备份',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handlePickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        setState(() {
          _importFilePath = filePath;
          _importPreview = null;
        });

        final service = ref.read(dataTransferServiceProvider);
        final preview = await service.previewImport(filePath);
        if (mounted) {
          setState(() => _importPreview = preview);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取文件失败：$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleImport() async {
    if (_importFilePath == null) return;

    setState(() => _isImporting = true);
    try {
      final service = ref.read(dataTransferServiceProvider);
      final result = await service.importData(
        _importFilePath!,
        strategy: _conflictStrategy,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入完成：${result.imported}条导入，${result.skipped}条跳过，${result.conflicted}条冲突'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _importFilePath = null;
          _importPreview = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
}
