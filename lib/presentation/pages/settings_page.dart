import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, '外观'),
          _buildThemeTile(context),
          const Divider(),
          _buildSectionHeader(context, '数据'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('数据管理'),
            subtitle: const Text('管理本地数据和缓存'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 实现数据管理
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('图片质量'),
            subtitle: const Text('高清'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 实现图片质量设置
            },
          ),
          const Divider(),
          _buildSectionHeader(context, '关于'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于应用'),
            subtitle: const Text('版本 1.0.0'),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('反馈建议'),
            onTap: () {
              // TODO: 实现反馈功能
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('主题'),
          subtitle: Text(_getThemeModeText(themeProvider.themeMode)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemeDialog(context, themeProvider),
        );
      },
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择主题'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(
                context,
                themeProvider,
                '浅色',
                ThemeMode.light,
              ),
              _buildThemeOption(
                context,
                themeProvider,
                '深色',
                ThemeMode.dark,
              ),
              _buildThemeOption(
                context,
                themeProvider,
                '跟随系统',
                ThemeMode.system,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    String title,
    ThemeMode mode,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    return ListTile(
      title: Text(title),
      leading: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : const Icon(Icons.circle_outlined),
      onTap: () {
        themeProvider.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('拍照姿势参考助手'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('版本: 1.0.0'),
              SizedBox(height: 8),
              Text('基于 4646 张糖水片美姿照片'),
              SizedBox(height: 8),
              Text('帮助您在人像拍摄时找到合适的姿势参考'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
