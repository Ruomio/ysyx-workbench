#!/bin/python

import sys
import matplotlib.pyplot as plt
import re

def main():
    sizes = []
    nums = []
    hit_rates = []

    # 读取标准输入
    for line in sys.stdin:
        # 检查结束条件
        if "All instances completed." in line:
            print('finish read')
            break
        # 匹配 SIZE 和 NUM
        size_match = re.search(r'SIZE=(\d+)', line)
        num_match = re.search(r'NUM=(\d+)', line)
        hit_match = re.search(r'Cache_Hit: \d+ Percentage:(\d+\.\d+)%', line)

        if size_match and num_match and hit_match:
            sizes.append(size_match.group(1))
            nums.append(int(num_match.group(1)))
            hit_rates.append(float(hit_match.group(1)))

    # 绘制折线图
    print(sizes + nums + hit_rates) 
    plt.figure(figsize=(10, 5))
    plt.plot(nums, hit_rates, marker='o')
    plt.title('Cache Hit Rate vs NUM')
    plt.xlabel('NUM')
    plt.ylabel('Cache Hit Rate (%)')
    plt.xticks(nums)
    plt.grid()
    plt.ylim(0, 100)
    plt.axhline(y=100, color='r', linestyle='--')  # 100% line for reference
    plt.show()

if __name__ == "__main__":
    main()