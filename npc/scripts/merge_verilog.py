#!/usr/bin/env python3

import os
import sys
import argparse
import re

def read_file_lines(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        return f.readlines()

def is_include_line(line):
    """匹配 `include "xxx" 行（忽略前后空格）"""
    return re.match(r'^\s*`include\s+"[^"]+"', line)

def normalize_path(p):
    return os.path.normpath(os.path.abspath(p))

def merge_verilog_files(
    source_files,
    output_file,
    define_filename="ysyx_24080020_DEFINE.v",
    add_file_markers=True
):
    # 规范化所有输入路径
    normalized_sources = [normalize_path(f) for f in source_files if os.path.isfile(f)]
    if not normalized_sources:
        print("[ERROR] No valid source files provided.", file=sys.stderr)
        sys.exit(1)

    # 查找 define.v 的实际路径（大小写敏感）
    define_path = None
    remaining = []
    seen = set()

    for f in normalized_sources:
        basename = os.path.basename(f)
        if basename == define_filename and define_path is None:
            define_path = f
        else:
            remaining.append(f)

    # 如果没找到 define.v，就按原顺序处理
    if define_path is None:
        print(f"[WARNING] '{define_filename}' not found in source list. Merging as-is.", file=sys.stderr)
        all_files = normalized_sources
    else:
        all_files = [define_path] + remaining

    # 去重（保留顺序）
    unique_files = []
    for f in all_files:
        if f not in seen:
            unique_files.append(f)
            seen.add(f)

    # 合并
    all_lines = []
    for f in unique_files:
        if add_file_markers:
            all_lines.append(f"\n// === BEGIN: {os.path.basename(f)} ===\n")
        for line in read_file_lines(f):
            if not is_include_line(line):
                all_lines.append(line)
        if add_file_markers:
            all_lines.append(f"// === END: {os.path.basename(f)} ===\n\n")

    # 写入
    with open(output_file, 'w', encoding='utf-8') as out:
        out.writelines(all_lines)

    print(f"[INFO] Merged {len(unique_files)} files into '{output_file}'")
    if define_path:
        print(f"[INFO] '{define_filename}' placed at top.")


def main():
    parser = argparse.ArgumentParser(
        description="Merge Verilog files into one. "
                    "Automatically place 'define.v' (or specified file) at the top, "
                    "remove all `include lines, and deduplicate files."
    )
    parser.add_argument(
        '--define-file', '-d',
        default='ysyx_24080020_DEFINE.v',
        help="Name of the macro definition file to promote to top (default: define.v)"
    )
    parser.add_argument(
        '--output', '-o',
        default='merged.v',
        help="Output file (default: merged.v)"
    )
    parser.add_argument(
        '--no-markers',
        action='store_true',
        help="Do not add BEGIN/END file markers"
    )
    parser.add_argument(
        'sources',
        nargs='+',
        help="List of Verilog source files (e.g., $(VERILOG_SRCS))"
    )

    args = parser.parse_args()

    merge_verilog_files(
        source_files=args.sources,
        output_file=args.output,
        define_filename=args.define_file,
        add_file_markers=not args.no_markers
    )

if __name__ == '__main__':
    main()
