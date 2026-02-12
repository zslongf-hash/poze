#!/usr/bin/env python3
"""
照片样本选择脚本
功能：从4646张照片中选择代表性样本（约100张）内置到应用中
"""

import os
import shutil
import random
from pathlib import Path

SOURCE_DIR = Path("/Users/jason/Documents/TRAE-app/post/post/res/糖水片美姿/_姿势参考系统")
OUTPUT_DIR = Path("/Users/jason/Documents/TRAE-app/post/post/pose_reference_app/assets/images/pose_samples")

TARGET_COUNT = 80

CATEGORIES = {
    "modern_standing": ("现代清新/站姿", 10),
    "modern_sitting": ("现代清新/坐姿", 10),
    "modern_dynamic": ("现代清新/动态", 10),
    "modern_interaction": ("现代清新/互动", 10),
    "ancient_standing": ("古风汉服/站姿", 10),
    "ancient_sitting": ("古风汉服/坐姿", 10),
    "ancient_dynamic": ("古风汉服/动态", 10),
    "ancient_interaction": ("古风汉服/互动", 10),
}

def collect_photos(category_path):
    photos = []
    for root, dirs, files in os.walk(category_path):
        for file in files:
            if file.endswith('.jpg'):
                photos.append(os.path.join(root, file))
    return photos

def select_samples():
    selected = []
    
    print(f"目标选择 {TARGET_COUNT} 张代表性照片\n")
    
    for category_key, (category_path, count) in CATEGORIES.items():
        full_path = SOURCE_DIR / category_path
        if not full_path.exists():
            print(f"⚠️  路径不存在: {full_path}")
            continue
            
        photos = collect_photos(str(full_path))
        
        if not photos:
            print(f"⚠️  没有找到照片: {category_path}")
            continue
        
        sample_size = min(count, len(photos))
        sampled = random.sample(photos, sample_size)
        
        for photo_path in sampled:
            rel_path = os.path.relpath(photo_path, SOURCE_DIR)
            new_filename = f"{category_key}_{os.path.basename(photo_path)}"
            selected.append({
                'source': photo_path,
                'destination': OUTPUT_DIR / new_filename,
                'original_rel': rel_path,
            })
        
        print(f"✅ {category_path}: 从 {len(photos)} 张中选择 {sample_size} 张")
    
    return selected

def copy_samples(samples):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    copied = 0
    for sample in samples:
        try:
            shutil.copy2(sample['source'], sample['destination'])
            copied += 1
        except Exception as e:
            print(f"❌ 复制失败: {sample['source']} -> {e}")
    
    print(f"\n已复制 {copied}/{len(samples)} 张照片到 {OUTPUT_DIR}")
    return copied

def generate_asset_manifest(samples):
    manifest_path = OUTPUT_DIR.parent / "asset_manifest.json"
    
    manifest = {
        "version": "1.0",
        "generated_at": str(Path(__file__).resolve()),
        "total_samples": len(samples),
        "categories": {},
        "files": []
    }
    
    for sample in samples:
        category = sample['original_rel'].split(os.sep)[0] + "_" + sample['original_rel'].split(os.sep)[1]
        if category not in manifest["categories"]:
            manifest["categories"][category] = 0
        manifest["categories"][category] += 1
        manifest["files"].append({
            "source": sample['original_rel'],
            "asset_path": f"assets/images/pose_samples/{Path(sample['destination']).name}",
            "category": category,
        })
    
    with open(manifest_path, 'w', encoding='utf-8') as f:
        import json
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    
    print(f"📋 资源清单已生成: {manifest_path}")
    return manifest

if __name__ == "__main__":
    random.seed(42)
    
    print("=" * 60)
    print("📸 照片样本选择工具")
    print("=" * 60)
    
    samples = select_samples()
    
    if samples:
        copied = copy_samples(samples)
        generate_asset_manifest(samples)
        
        print("\n" + "=" * 60)
        print(f"🎉 完成！已选择 {len(samples)} 张代表性照片")
        print("=" * 60)
    else:
        print("\n❌ 没有找到任何照片")
