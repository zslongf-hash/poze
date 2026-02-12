#!/usr/bin/env python3
"""
原地压缩图片脚本
降低图片质量以减小应用打包体积
"""

import os
from pathlib import Path
from PIL import Image
from concurrent.futures import ProcessPoolExecutor, as_completed
import argparse


def compress_image(args):
    """
    压缩单张图片

    Args:
        args: 元组 (图片路径, 目标质量, 最大尺寸)

    Returns:
        元组 (图片路径, 原始大小, 压缩后大小, 是否成功)
    """
    img_path, quality, max_size = args

    try:
        # 获取原始文件大小
        original_size = os.path.getsize(img_path)

        # 打开图片
        with Image.open(img_path) as img:
            # 转换为RGB模式（处理RGBA或其他模式）
            if img.mode in ('RGBA', 'P'):
                img = img.convert('RGB')

            # 检查是否需要调整尺寸
            width, height = img.size
            if max_size and (width > max_size or height > max_size):
                # 按比例缩放
                ratio = min(max_size / width, max_size / height)
                new_width = int(width * ratio)
                new_height = int(height * ratio)
                img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

            # 保存压缩后的图片
            img.save(img_path, 'JPEG', quality=quality, optimize=True)

        # 获取压缩后大小
        compressed_size = os.path.getsize(img_path)

        return (img_path, original_size, compressed_size, True)

    except Exception as e:
        return (img_path, 0, 0, False)


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='压缩图片以减小应用体积')
    parser.add_argument('--quality', type=int, default=75,
                        help='JPEG质量 (1-95, 默认75)')
    parser.add_argument('--max-size', type=int, default=1200,
                        help='最大边长像素 (默认1200)')
    parser.add_argument('--workers', type=int, default=8,
                        help='并行处理进程数 (默认8)')
    parser.add_argument('--dry-run', action='store_true',
                        help='试运行模式，不实际压缩')

    args = parser.parse_args()

    # 图片目录
    images_dir = Path('/Users/jason/Documents/TRAE-app/post/post/pose_reference_app/assets/images/pose_samples')

    # 获取所有jpg图片
    image_files = sorted(images_dir.glob('*.jpg'))

    if not image_files:
        print("未找到图片文件")
        return

    print(f"找到 {len(image_files)} 张图片")
    print(f"压缩参数: 质量={args.quality}, 最大尺寸={args.max_size}px")
    print("-" * 50)

    if args.dry_run:
        print("试运行模式 - 不执行实际压缩")
        return

    # 准备任务参数
    task_args = [(str(img), args.quality, args.max_size) for img in image_files]

    # 并行处理
    total_original = 0
    total_compressed = 0
    success_count = 0
    failed_count = 0

    with ProcessPoolExecutor(max_workers=args.workers) as executor:
        futures = {executor.submit(compress_image, arg): arg for arg in task_args}

        for i, future in enumerate(as_completed(futures)):
            img_path, original_size, compressed_size, success = future.result()

            if success:
                total_original += original_size
                total_compressed += compressed_size
                success_count += 1

                # 每100张显示进度
                if (i + 1) % 100 == 0 or (i + 1) == len(image_files):
                    progress = (i + 1) / len(image_files) * 100
                    print(f"进度: {progress:.1f}% ({i + 1}/{len(image_files)})")
            else:
                failed_count += 1
                print(f"失败: {img_path}")

    # 显示结果
    print("-" * 50)
    print("压缩完成!")
    print(f"成功: {success_count} 张")
    print(f"失败: {failed_count} 张")

    if total_original > 0:
        saved_bytes = total_original - total_compressed
        saved_percent = (saved_bytes / total_original) * 100

        original_mb = total_original / (1024 * 1024)
        compressed_mb = total_compressed / (1024 * 1024)
        saved_mb = saved_bytes / (1024 * 1024)

        print(f"\n原始大小: {original_mb:.2f} MB")
        print(f"压缩后大小: {compressed_mb:.2f} MB")
        print(f"节省空间: {saved_mb:.2f} MB ({saved_percent:.1f}%)")


if __name__ == '__main__':
    main()
