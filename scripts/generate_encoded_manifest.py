#!/usr/bin/env python3
"""
生成支持12位编码的asset_manifest.json
"""

import json
from pathlib import Path

# 12位编码定义
ENCODING_CODES = {
    'shot_size': {      # 第1位 - 景别
        'a': '特写', 'b': '近景', 'c': '中景', 'd': '全景', 'e': '远景', 'f': '大远景', 'z': '未知'
    },
    'composition': {    # 第2位 - 构图
        'a': '中心构图', 'b': '三分法', 'c': '对称构图', 'd': '对角线', 'e': '框架构图', 
        'f': '留白', 'g': '黄金分割', 'h': '引导线', 'z': '未知'
    },
    'angle': {          # 第3位 - 拍摄角度
        'a': '平视', 'b': '俯拍', 'c': '仰拍', 'd': '侧拍', 'e': '45度角',
        'f': '正脸', 'g': '侧脸', 'h': '背影', 'i': '低角度', 'j': '高角度', 'z': '未知'
    },
    'pose': {           # 第4位 - 人物姿态
        'a': '站姿', 'b': '坐姿', 'c': '蹲姿', 'd': '卧姿', 'e': '跪姿', 'z': '未知'
    },
    'action': {         # 第5位 - 动作类型
        'a': '静态', 'b': '行走', 'c': '跳跃', 'd': '旋转', 'e': '倚靠', 'f': '抬手',
        'g': '抚脸', 'h': '撩发', 'i': '叉腰', 'j': '抱臂', 'k': '踢腿', 'l': '弯腰',
        'm': '伸展', 'n': '互动', 'z': '未知'
    },
    'emotion': {        # 第6位 - 情绪
        'a': '开心', 'b': '忧郁', 'c': '自信', 'd': '温柔', 'e': '酷飒', 'f': '性感',
        'g': '知性', 'h': '呆萌', 'i': '严肃', 'j': '神秘', 'k': '慵懒', 'l': '活泼',
        'm': '优雅', 'n': '叛逆', 'z': '未知'
    },
    'clothing': {       # 第7位 - 服装类型
        'a': '长袖', 'b': '短袖', 'c': '长裤', 'd': '短裤', 'e': '长裙', 'f': '短裙',
        'g': '连衣裙', 'h': '外套', 'i': '背心', 'j': '西装', 'k': '运动装', 'l': '休闲装', 'z': '未知'
    },
    'hair': {           # 第8位 - 发型
        'a': '长发', 'b': '短发', 'c': '盘发', 'd': '马尾', 'e': '卷发',
        'f': '直发', 'g': '编发', 'h': '帽子', 'z': '未知'
    },
    'color': {          # 第9位 - 服装颜色
        'a': '黑色', 'b': '白色', 'c': '灰色', 'd': '红色', 'e': '蓝色', 'f': '绿色',
        'g': '黄色', 'h': '粉色', 'i': '紫色', 'j': '棕色', 'k': '橙色', 'l': '多彩/印花',
        'm': '米色', 'n': '藏青', 'z': '未知'
    },
    'season': {         # 第10位 - 季节
        'a': '春季', 'b': '夏季', 'c': '秋季', 'd': '冬季', 'e': '四季通用', 'z': '未知'
    },
    'scene': {          # 第11位 - 场景
        'a': '室内纯色', 'b': '室内布景', 'c': '街道', 'd': '公园', 'e': '海边',
        'f': '建筑', 'g': '自然', 'h': '工作室', 'i': '咖啡厅', 'j': '书店',
        'k': '居家', 'l': '办公室', 'z': '未知'
    },
    'style': {          # 第12位 - 风格
        'a': '前卫', 'b': '运动休闲', 'c': '复古', 'd': '极简', 'e': '波西米亚',
        'f': '商务', 'g': '民族', 'h': '哥特', 'i': '朋克', 'j': '街头',
        'k': '学院', 'l': '浪漫', 'm': '优雅', 'n': '甜美', 'o': '日系', 'p': '韩系', 'z': '未知'
    }
}


def parse_encoded_filename(filename):
    """
    解析编码后的文件名
    格式: 0001-eaabbgcbbegd.jpg
    返回: (序号, 12位编码字典)
    """
    stem = Path(filename).stem
    parts = stem.split('-')
    
    if len(parts) != 2 or len(parts[1]) != 12:
        return None, None
    
    seq = parts[0]
    code = parts[1]
    
    # 解析12位编码
    encoding = {
        'shot_size': {'code': code[0], 'name': ENCODING_CODES['shot_size'].get(code[0], '未知')},
        'composition': {'code': code[1], 'name': ENCODING_CODES['composition'].get(code[1], '未知')},
        'angle': {'code': code[2], 'name': ENCODING_CODES['angle'].get(code[2], '未知')},
        'pose': {'code': code[3], 'name': ENCODING_CODES['pose'].get(code[3], '未知')},
        'action': {'code': code[4], 'name': ENCODING_CODES['action'].get(code[4], '未知')},
        'emotion': {'code': code[5], 'name': ENCODING_CODES['emotion'].get(code[5], '未知')},
        'clothing': {'code': code[6], 'name': ENCODING_CODES['clothing'].get(code[6], '未知')},
        'hair': {'code': code[7], 'name': ENCODING_CODES['hair'].get(code[7], '未知')},
        'color': {'code': code[8], 'name': ENCODING_CODES['color'].get(code[8], '未知')},
        'season': {'code': code[9], 'name': ENCODING_CODES['season'].get(code[9], '未知')},
        'scene': {'code': code[10], 'name': ENCODING_CODES['scene'].get(code[10], '未知')},
        'style': {'code': code[11], 'name': ENCODING_CODES['style'].get(code[11], '未知')},
    }
    
    return seq, encoding


def generate_manifest():
    """生成asset_manifest.json"""
    base_dir = Path('assets/images/pose_samples')
    
    files = []
    for img_path in sorted(base_dir.glob('*.jpg')):
        seq, encoding = parse_encoded_filename(img_path.name)
        if seq and encoding:
            files.append({
                'asset_path': f'assets/images/pose_samples/{img_path.name}',
                'filename': img_path.name,
                'sequence': seq,
                'encoding': encoding,
                'full_code': ''.join([encoding[k]['code'] for k in ['shot_size', 'composition', 'angle', 'pose', 'action', 'emotion', 'clothing', 'hair', 'color', 'season', 'scene', 'style']])
            })
    
    manifest = {
        'version': '2.0',
        'encoding_version': 'v3',
        'total_images': len(files),
        'encoding_definitions': ENCODING_CODES,
        'files': files
    }
    
    # 保存manifest
    output_path = Path('assets/images/asset_manifest.json')
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    
    print(f"生成完成!")
    print(f"共 {len(files)} 张照片")
    print(f"保存到: {output_path}")
    
    # 显示前3个示例
    print("\n前3个示例:")
    for f in files[:3]:
        print(f"\n{f['filename']}")
        print(f"  序号: {f['sequence']}")
        print(f"  编码: {f['full_code']}")
        print(f"  景别: {f['encoding']['shot_size']['name']}")
        print(f"  服装: {f['encoding']['clothing']['name']}")
        print(f"  发型: {f['encoding']['hair']['name']}")


if __name__ == '__main__':
    generate_manifest()
