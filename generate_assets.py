#!/usr/bin/env python3
"""
生成 pubspec.yaml 的资产配置部分
"""
import os

base_path = "assets/images/pose_samples"
assets = []

# 获取所有子目录
for dir_name in sorted(os.listdir(base_path)):
    dir_path = os.path.join(base_path, dir_name)
    if os.path.isdir(dir_path):
        assets.append(f"    - {base_path}/{dir_name}/")

# 输出资产配置
print("  assets:")
for asset in assets:
    print(asset)
print("    - assets/images/asset_manifest.json")
print("    - assets/data/")
print("    - assets/icons/")
