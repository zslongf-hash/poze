#!/usr/bin/env python3
"""
简化标签系统，只保留准确的分类信息
移除不准确自动生成的姿势标签
"""

import json
from pathlib import Path

def update_manifest_with_simple_tags():
    """更新 asset_manifest.json，使用简化的标签系统"""
    manifest_path = Path('assets/images/asset_manifest.json')
    
    with open(manifest_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    files = data.get('files', [])
    print(f"正在更新 {len(files)} 张照片的标签...")
    
    # 为每张照片添加简化标签
    for item in files:
        category = item.get('category', '')
        
        # 从分类中提取信息
        parts = category.split('_')
        
        # 解析风格和服装类型
        style_name = ""
        clothing_type = ""
        
        if len(parts) >= 2:
            # 风格部分
            if 'style' in parts:
                style_idx = parts.index('style')
                style_key = '_'.join(parts[:style_idx+1])
                style_name = get_style_name(style_key)
            elif parts[0] in ['athleisure', 'minimalist', 'vintage', 'urban', 'gothic', 'punk', 'street', 'retro', 'romantic', 'preppy', 'bohemian', 'ethnic']:
                style_name = get_style_name(parts[0])
            
            # 服装类型部分
            if 'wear' in parts:
                wear_idx = parts.index('wear')
                if wear_idx > 0:
                    type_key = '_'.join(parts[wear_idx-1:wear_idx+1])
                    clothing_type = get_clothing_type(type_key)
        
        # 简化的标签，只保留确定的信息
        simple_tags = {
            'style': style_name,
            'clothing_type': clothing_type,
            'category': category,
        }
        
        # 替换原有的 pose_tags
        item['simple_tags'] = simple_tags
        # 删除不准确的 pose_tags
        if 'pose_tags' in item:
            del item['pose_tags']
    
    # 保存更新后的 manifest
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n完成！已更新 {len(files)} 张照片的标签")
    
    # 打印一些示例
    print("\n示例数据：")
    for item in files[:3]:
        print(f"\n文件: {item['asset_path']}")
        print(f"  简化标签: {json.dumps(item['simple_tags'], ensure_ascii=False)}")

def get_style_name(style_key: str) -> str:
    """获取风格中文名"""
    style_map = {
        'edgy_style': '前卫风格',
        'athleisure': '运动休闲',
        'party_wear': '派对装',
        'minimalist': '极简主义',
        'vintage_style': '复古风格',
        'punk_style': '朋克风格',
        'urban_style': '都市风格',
        'street_style': '街头风格',
        'gothic_style': '哥特风格',
        'retro_style': '复古风格',
        'romantic_style': '浪漫风格',
        'preppy_style': '学院风格',
        'bohemian_style': '波西米亚',
        'ethnic_wear': '民族风',
        'business_wear': '商务装',
        'sports_wear': '运动装',
        'summer_wear': '夏季装',
        'winter_wear': '冬季装',
        'casual_wear': '休闲装',
        'formal_wear': '正装',
    }
    return style_map.get(style_key, style_key)

def get_clothing_type(type_key: str) -> str:
    """获取服装类型中文名"""
    type_map = {
        'casual_wear': '休闲装',
        'formal_wear': '正装',
        'sports_wear': '运动装',
        'summer_wear': '夏季装',
        'winter_wear': '冬季装',
        'party_wear': '派对装',
        'business_wear': '商务装',
        'ethnic_wear': '民族装',
    }
    return type_map.get(type_key, type_key)

if __name__ == '__main__':
    update_manifest_with_simple_tags()
