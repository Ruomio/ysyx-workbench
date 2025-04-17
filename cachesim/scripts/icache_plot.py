#!/bin/env python

import sys
import matplotlib.pyplot as plt
import re
import signal
from mpl_toolkits.mplot3d import Axes3D

def main():
    sizes = []
    nums = []
    ways = []
    hit_rates = []

    # 读取标准输入
    for line in sys.stdin:
        # 检查结束条件
        if "All instances completed." in line:
            break
        # 匹配 SIZE 和 NUM WAY
        size_match = re.search(r'SIZE=(\d+)', line)
        num_match = re.search(r'NUM=(\d+)', line)
        way_match = re.search(r'WAY=(\d+)', line)
        hit_match = re.search(r'Cache_Hit: \d+ Percentage:(\d+\.\d+)%', line)

        if size_match and num_match and way_match:
            sizes.append(int(size_match.group(1)))
            nums.append(int(num_match.group(1)))
            ways.append(int(way_match.group(1)))
        if hit_match:
            hit_rates.append(float(hit_match.group(1)))

    # 生成图表
    plot_cache_performance(nums, ways, sizes, hit_rates)


def plot_cache_performance(nums, ways, sizes, hit_rates):
    unique_ways = set(ways)
    unique_sizes = set(sizes)

    # 创建子图
    num_plots = len(unique_ways) * len(unique_sizes)
    fig, axes = plt.subplots(len(unique_sizes), len(unique_ways), figsize=(15, 10))

    for i, size in enumerate(unique_sizes):
        for j, way in enumerate(unique_ways):
            # 筛选出对应的命中率数据
            filtered_nums = [num for k, num in enumerate(nums) if ways[k] == way and sizes[k] == size]
            filtered_hits = [hit_rates[k] for k in range(len(hit_rates)) if ways[k] == way and sizes[k] == size]

            # 绘制图表
            ax = axes[i, j]
            ax.plot(filtered_nums, filtered_hits, marker='o')
            ax.set_title(f'WAY={way}, SIZE={size}')
            ax.set_xlabel('Number of Cache Groups (NUM)')
            ax.set_ylabel('Cache Hit Rate (%)')
            ax.grid()

    plt.tight_layout()
    plt.show()

def signal_handler(sig, frame):
    print("\nExiting gracefully...")
    sys.exit(0)

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)
    main()
