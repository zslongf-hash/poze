import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/managers/user_stats_manager.dart';
import '../../core/constants/app_constants.dart';

/// 统计详情页面
/// 展示用户的使用统计数据分析
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final UserStatsManager _statsManager = UserStatsManager();
  bool _isLoading = true;
  UserStats _stats = UserStats();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    await _statsManager.initialize();
    if (mounted) {
      setState(() {
        _stats = _statsManager.stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshStats() async {
    setState(() {
      _isLoading = true;
    });
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('摄影之旅'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeaderSection(),
                    _buildOverviewCards(),
                    if (_stats.styleViews.isNotEmpty) _buildStyleStatsSection(),
                    if (_stats.categoryViews.isNotEmpty) _buildCategoryStatsSection(),
                    if (_stats.poseViews.isNotEmpty) _buildPoseStatsSection(),
                    if (_stats.recentViews.isNotEmpty) _buildRecentViewsSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  /// 头部统计摘要
  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade400, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '已浏览 ${_stats.totalViews} 个姿势',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '收藏了 ${_stats.totalFavorites} 个喜欢的姿势',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '最后更新: ${_formatDate(_stats.lastUpdated)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 概览数据卡片
  Widget _buildOverviewCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.style,
              title: '偏好风格',
              value: '${_stats.styleViews.length}',
              subtitle: '种',
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.category,
              title: '浏览分类',
              value: '${_stats.categoryViews.length}',
              subtitle: '个',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.accessibility,
              title: '姿势类型',
              value: '${_stats.poseViews.length}',
              subtitle: '种',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 风格偏好统计
  Widget _buildStyleStatsSection() {
    final sortedStyles = _stats.styleViews.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildStatsSection(
      title: '风格偏好',
      icon: Icons.style,
      color: Colors.orange,
      child: Column(
        children: sortedStyles.take(5).map((entry) {
          final total = _stats.styleViews.values.fold(0, (a, b) => a + b);
          final percentage = total > 0 ? (entry.value / total * 100).toInt() : 0;
          return _buildProgressItem(
            label: entry.key,
            value: entry.value,
            percentage: percentage,
            color: Colors.orange,
          );
        }).toList(),
      ),
    );
  }

  /// 分类浏览统计
  Widget _buildCategoryStatsSection() {
    final sortedCategories = _stats.categoryViews.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildStatsSection(
      title: '常看分类',
      icon: Icons.category,
      color: Colors.blue,
      child: Column(
        children: sortedCategories.take(5).map((entry) {
          final total = _stats.categoryViews.values.fold(0, (a, b) => a + b);
          final percentage = total > 0 ? (entry.value / total * 100).toInt() : 0;
          return _buildProgressItem(
            label: entry.key,
            value: entry.value,
            percentage: percentage,
            color: Colors.blue,
          );
        }).toList(),
      ),
    );
  }

  /// 姿势类型统计
  Widget _buildPoseStatsSection() {
    final sortedPoses = _stats.poseViews.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildStatsSection(
      title: '姿势偏好',
      icon: Icons.accessibility,
      color: Colors.green,
      child: Column(
        children: sortedPoses.take(5).map((entry) {
          final total = _stats.poseViews.values.fold(0, (a, b) => a + b);
          final percentage = total > 0 ? (entry.value / total * 100).toInt() : 0;
          return _buildProgressItem(
            label: entry.key,
            value: entry.value,
            percentage: percentage,
            color: Colors.green,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required String label,
    required int value,
    required int percentage,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$value次 ($percentage%)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  /// 最近浏览记录
  Widget _buildRecentViewsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: Colors.purple.shade400, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '最近浏览',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '共${_stats.recentViews.length}条',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._stats.recentViews.take(10).map((item) {
            return _buildRecentItem(item);
          }),
        ],
      ),
    );
  }

  Widget _buildRecentItem(ViewHistoryItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                item.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image, color: Colors.grey.shade400);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.style ?? '未知风格',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(item.viewedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
