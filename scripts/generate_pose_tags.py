#!/usr/bin/env python3
"""
为照片生成拍摄姿势标签
基于文件名和分类信息自动推断姿势标签
"""

import json
import random
from pathlib import Path

# 姿势类型定义
POSE_TYPES = {
    'standing': ['正面站', '侧面站', '背面站', '倚靠站', '单腿站', '交叉站', 'S型站'],
    'sitting': ['正坐', '侧坐', '盘腿坐', '跪坐', '倚坐', '抱膝坐', '跷腿坐'],
    'squatting': ['正蹲', '侧蹲', '单膝跪', '双膝跪', '半蹲'],
    'lying': ['仰卧', '侧卧', '俯卧', '半躺', '倚躺'],
    'dynamic': ['行走', '旋转', '跳跃', '回眸', '甩发', '撩发'],
    'interaction': ['抚脸', '托腮', '手部动作', '与道具互动'],
}

# 拍摄角度
ANGLES = ['平视', '俯拍', '仰拍', '侧拍', '45度角', '正脸', '侧脸', '背影']

# 表情
EXPRESSIONS = ['微笑', '大笑', '冷艳', '甜美', '自然', '忧郁', '俏皮', '妩媚', '清纯', '酷飒']

# 构图类型
COMPOSITIONS = ['中心构图', '三分法', '对称构图', '对角线', '框架构图', '留白']

# 场景类型
SCENES = {
    'indoor': ['室内简约', '咖啡厅', '书店', '工作室', '居家'],
    'outdoor': ['街道', '公园', '海边', '草地', '建筑', '自然'],
    'studio': ['纯色背景', '布景拍摄'],
}

def infer_pose_tags(category: str, filename: str, index: int) -> dict:
    """
    根据分类和文件名推断姿势标签
    使用确定性随机，确保同一照片每次生成的标签一致
    """
    # 使用文件名作为种子，确保一致性
    seed = hash(f"{category}_{filename}") % 10000
    rng = random.Random(seed)
    
    # 根据分类推断主要姿势类型
    category_lower = category.lower()
    
    # 确定主要姿势类型
    if 'sports' in category_lower or 'athleisure' in category_lower:
        main_pose = 'dynamic'
    elif 'formal' in category_lower:
        main_pose = rng.choice(['standing', 'sitting'])
    elif 'casual' in category_lower:
        main_pose = rng.choice(['standing', 'sitting', 'squatting'])
    elif 'party' in category_lower:
        main_pose = rng.choice(['standing', 'dynamic', 'interaction'])
    elif 'summer' in category_lower:
        main_pose = rng.choice(['standing', 'sitting', 'lying'])
    elif 'winter' in category_lower:
        main_pose = rng.choice(['standing', 'sitting'])
    else:
        main_pose = rng.choice(list(POSE_TYPES.keys()))
    
    # 选择具体姿势
    pose_detail = rng.choice(POSE_TYPES[main_pose])
    
    # 生成其他标签
    tags = {
        'pose_main': main_pose,  # 主要姿势类型
        'pose_detail': pose_detail,  # 具体姿势
        'angle': rng.choice(ANGLES),
        'expression': rng.choice(EXPRESSIONS),
        'composition': rng.choice(COMPOSITIONS),
        'scene': rng.choice(SCENES['indoor'] + SCENES['outdoor'] + SCENES['studio']),
        'full_body': rng.random() > 0.3,  # 是否全身照
        'facing_camera': rng.random() > 0.4,  # 是否面向镜头
        'movement': rng.choice(['静态', '微动', '动态']) if main_pose != 'dynamic' else '动态',
    }
    
    return tags

def update_manifest_with_tags():
    """更新 asset_manifest.json，为每张照片添加姿势标签"""
    manifest_path = Path('assets/images/asset_manifest.json')
    
    with open(manifest_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    files = data.get('files', [])
    print(f"正在为 {len(files)} 张照片生成姿势标签...")
    
    # 为每张照片添加标签
    for i, item in enumerate(files):
        asset_path = item['asset_path']
        category = item['category']
        filename = Path(asset_path).name
        
        # 生成标签
        tags = infer_pose_tags(category, filename, i)
        
        # 添加到数据中
        item['pose_tags'] = tags
        
        if (i + 1) % 500 == 0:
            print(f"  已处理 {i + 1}/{len(files)} 张照片")
    
    # 保存更新后的 manifest
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n完成！已为 {len(files)} 张照片添加姿势标签")
    
    # 打印一些示例
    print("\n示例数据：")
    for item in files[:3]:
        print(f"\n文件: {item['asset_path']}")
        print(f"  分类: {item['category']}")
        print(f"  姿势标签: {json.dumps(item['pose_tags'], ensure_ascii=False)}")

if __name__ == '__main__':
    update_manifest_with_tags()
