# 应用截图指南

本目录用于存放 Poze 应用的截图，用于 GitHub README 展示。

## 所需截图

请截取以下6张截图（推荐使用 Android 模拟器或真机）：

| 文件名 | 说明 | 截图内容 |
|--------|------|----------|
| `home.png` | 首页 | 展示热门风格、猜你喜欢、快速筛选 |
| `browse.png` | 浏览页 | 展示姿势网格、筛选标签 |
| `detail.png` | 详情页 | 展示姿势大图、Dock栏、操作按钮 |
| `favorites.png` | 收藏页 | 展示收藏的姿势列表 |
| `stats.png` | 统计页 | 展示使用统计数据 |
| `filter.png` | 筛选 | 展示筛选选项弹窗 |

## 截图要求

- **分辨率**: 1080 x 1920 (或等比例)
- **格式**: PNG
- **大小**: 尽量控制在 500KB 以内
- **内容**: 确保无敏感信息，展示最佳状态

## 截图方法

### Android
```bash
# 方法1: 使用 adb
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png screenshots/home.png

# 方法2: 使用 Android Studio
# View -> Tool Windows -> Logcat -> 点击相机图标
```

### iOS
```bash
# 模拟器: Cmd + S 保存截图
# 真机: 电源键 + 音量上键
```

### Flutter
```bash
# 运行应用后截图
flutter run
# 然后使用上述方法截图
```

## 截图后

1. 将截图放入此目录
2. 删除此 README.md 文件
3. 提交到 Git:
```bash
git add screenshots/
git commit -m "docs: 添加应用截图"
git push
```
