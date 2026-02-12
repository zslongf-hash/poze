#!/usr/bin/env python3
"""
为照片添加景别标签
基于分类和随机分配策略，确保各景别分布合理
"""

import json
import random
from pathlib import Path
from collections import Counter

# 景别定义
SHOT_SIZES = ['特写', '近景', '中景', '全景', '远景']

# 基于服装类型的景别倾向
# 某些服装类型更适合特定景别
SHOT_SIZE_BIAS = {
    'formal_wear': {'特写': 0.1, '近景': 0.2, '中景': 0.4, '全景': 0.25, '远景': 0.05},
    'casual_wear': {'特写': 0.15, '近景': 0.25, '中景': 0.35, '全景': 0.2, '远景': 0.05},
    'sports_wear': {'特写': 0.1, '近景': 0.2, '中景': 0.4, '全景': 0.25, '远景': 0.05},
    'summer_wear': {'特写': 0.2, '近景': 0.3, '中景': 0.3, '全景': 0.15, '远景': 0.05},
    'winter_wear': {'特写': 0.05, '近景': 0.15, '中景': 0.4, '全景': 0.3, '远景': 0.1},
    'party_wear': {'特写': 0.15, '近景': 0.25, '中景': 0.35, '全景': 0.2, '远景': 0.05},
    'business_wear': {'特写': 0.05, '近景': 0.15, '中景': 0.45, '全景': 0.3, '远景': 0.05},
    'ethnic_wear': {'特写': 0.1, '近景': 0.2, '中景': 0.35, '全景': 0.3, '远景': 0.05},
}

def get_shot_size_by_category(category: str, filename: str, rng: random.Random) -> str:
    """
    根据分类获取景别，使用加权随机
    """
    # 提取服装类型
    clothing_type = None
    for ct in SHOT_SIZE_BIAS.keys():
        if ct in category:
            clothing_type = ct
            break
    
    if clothing_type:
        # 使用加权分布
        weights = SHOT_SIZE_BIAS[clothing_type]
        shot_sizes = list(weights.keys())
        probabilities = list(weights.values())
        return rng.choices(shot_sizes, weights=probabilities)[0]
    else:
        # 默认均匀分布
        return rng.choice(SHOT_SIZES)

def add_shot_size_tags():
    """为所有照片添加景别标签"""
    manifest_path = Path('assets/images/asset_manifest.json')
    
    with open(manifest_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    files = data.get('files', [])
    print(f"正在为 {len(files)} 张照片添加景别标签...")
    
    # 统计分布
    distribution = Counter()
    
    # 为每张照片添加景别标签
    for item in files:
        category = item.get('category', '')
        filename = Path(item['asset_path']).name
        
        # 使用文件名hash作为随机种子，确保同一照片每次分配相同的景别
        seed = hash(f"{category}_{filename}_shot_size") % 10000
        rng = random.Random(seed)
        
        # 获取景别
        shot_size = get_shot_size_by_category(category, filename, rng)
        
        # 添加到 simple_tags
        if 'simple_tags' not in item:
            item['simple_tags'] = {}
        item['simple_tags']['shot_size'] = shot_size
        
        distribution[shot_size] += 1
        
        if (list(files).index(item) + 1) % 500 == 0:
            print(f"  已处理 {list(files).index(item) + 1}/{len(files)} 张照片")
    
    # 保存更新后的 manifest
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n完成！已为 {len(files)} 张照片添加景别标签")
    
    # 打印分布统计
    print("\n景别分布统计：")
    for shot_size in SHOT_SIZES:
