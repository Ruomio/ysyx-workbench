#!/bin/env python

import sys
import matplotlib.pyplot as plt
import re
from mpl_toolkits.mplot3d import Axes3D

def main():
    sizes = []
    nums = []
    hit_rates = []

    # 读取标准输入
    for line in sys.stdin:
        # 检查结束条件
        if "All instances completed." in line:
            break
        # 匹配 SIZE 和 NUM
        size_match = re.search(r'SIZE=(\d+)', line)
        num_match = re.search(r'NUM=(\d+)', line)
        hit_match = re.search(r'Cache_Hit: \d+ Percentage:(\d+\.\d+)%', line)

        if size_match and num_match:
            sizes.append(size_match.group(1))
            nums.append(int(num_match.group(1)))
        if hit_match:
            hit_rates.append(float(hit_match.group(1)))


    unique_sizes = set(sizes)  # 获取唯一的 SIZE 值

     # 创建二维图形
    plt.figure(figsize=(10, 7))

    # 为每个 SIZE 绘制数据点
    for size in unique_sizes:
        indices = [i for i, s in enumerate(sizes) if s == size]
        plt.plot([nums[i] for i in indices], 
                 [hit_rates[i] for i in indices], 
                 marker='o', label=f'SIZE={size}')  # 使用折线图

    plt.title('Cache Hit Rate vs NUM by SIZE')
    plt.xlabel('NUM')
    plt.ylabel('Cache Hit Rate (%)')
    plt.legend()  # 添加图例
    plt.grid()
    plt.show()


    # 创建三维图形
    # fig = plt.figure(figsize=(10, 7))
    # ax = fig.add_subplot(111, projection='3d')

    # # 为每个 SIZE 绘制折线
    # for size in unique_sizes:
    #     indices = [i for i, s in enumerate(sizes) if s == size]
    #     ax.plot([nums[i] for i in indices], 
    #             [hit_rates[i] for i in indices], 
    #             [sizes[i] for i in indices], 
    #             marker='o', label=f'SIZE={size}')  # 使用不同的线

    # ax.set_title('Cache Hit Rate vs NUM and SIZE')
    # ax.set_xlabel('NUM')
    # ax.set_ylabel('Cache Hit Rate (%)')
    # ax.set_zlabel('SIZE')

    # # 调整坐标轴刻度方向
    # ax.tick_params(axis='x', direction='in')  # x 轴刻度向内
    # ax.tick_params(axis='y', direction='inout')  # y 轴刻度向内
    # ax.tick_params(axis='z', direction='in')  # z 轴刻度向内

    # # 调整坐标轴方向
    # ax.view_init(elev=60, azim=154, roll=-113)  # 调整视角

    # ax.grid()
    # plt.show() 


if __name__ == "__main__":
    main()