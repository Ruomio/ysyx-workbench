#!/bin/bash
# set -x

# 获取脚本所在的目录
SCRIPT_DIR="${NEMU_HOME}/../cachesim"

BIN=${SCRIPT_DIR}/build/cachesim
INSTS=${NEMU_HOME}/build/insts.txt

SIZES=(4 8 16 32)
NUMS=(4 8 16 32 64)
# SIZES=(4)
# NUMS=(16)

# 批量运行
for size in "${SIZES[@]}"; do
    for num in "${NUMS[@]}"; do
        echo "Running with SIZE=$size and NUM=$num..."
        
        # 运行命令
        "$BIN" "${INSTS}" $size $num
        
        echo ""
    done
done

echo "All instances completed."