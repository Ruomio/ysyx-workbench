#!/usr/bin/env python3

from sys import argv

hex_file = argv[1]
max_len = int(argv[2])
placeholder = argv[3]  # 原始字符串，如 "The insert-arg..."
mainargs = argv[4]

if len(mainargs) > max_len:
    print("Error: mainargs should not be longer than {0} bytes".format(max_len))
    exit(1)

# print("mainargs={0}".format(mainargs))

# 将 placeholder 转为字节列表
placeholder_bytes = [ord(c) for c in placeholder]
# print(f"Searching for {len(placeholder_bytes)} bytes: {placeholder_bytes[:5]}...")

# 读取 .hex 文件，解析成字节列表 + 记录原始行结构
all_bytes = []      # 所有数据字节
addr_lines = []     # 地址行 (@xxxxxxx)
data_line_ranges = []  # 每个数据行对应的字节范围 [(start, end), ...]

with open(hex_file, 'r', encoding='ascii') as fp:
    lines = fp.readlines()

current_byte_index = 0
for line in lines:
    stripped = line.strip()
    if stripped.startswith('@'):
        addr_lines.append((len(all_bytes), stripped))  # 记录地址行位置和内容
    else:
        # 分割字节
        bytes_in_line = [int(x, 16) for x in stripped.split() if x]
        all_bytes.extend(bytes_in_line)
        # 记录这个数据行对应的字节范围
        start_idx = current_byte_index
        end_idx = current_byte_index + len(bytes_in_line)
        data_line_ranges.append((start_idx, end_idx, stripped))
        current_byte_index = end_idx

# 在 all_bytes 中查找 placeholder
found_offset = -1
for i in range(len(all_bytes) - len(placeholder_bytes) + 1):
    match = True
    for j in range(len(placeholder_bytes)):
        if all_bytes[i + j] != placeholder_bytes[j]:
            match = False
            break
    if match:
        found_offset = i
        break

if found_offset == -1:
    print("Error: placeholder not found!")
    print("Searched for bytes:", placeholder_bytes)
    exit(1)

# print(f"Found placeholder at byte offset {found_offset}")

# 构造替换内容
replacement_bytes = [ord(c) for c in mainargs] + [0] * (max_len - len(mainargs))
if len(replacement_bytes) != max_len:
    print("Error: replacement length mismatch!")
    exit(1)

# 替换字节
all_bytes[found_offset:found_offset + len(placeholder_bytes)] = replacement_bytes

# 重新格式化为原始格式（保持地址行和每行字节数）
new_lines = []
byte_index = 0

# 重建数据行
for start, end, orig_line in data_line_ranges:
    # 如果这个行范围被修改了，重新生成；否则保留原行
    if start <= found_offset < end or start < found_offset + len(placeholder_bytes) <= end:
        # 这个行被影响，需要重新生成
        line_bytes = all_bytes[start:end]
        new_line = ' '.join(f"{b:02x}" for b in line_bytes)
        new_lines.append(new_line + '\n')
    else:
        # 未被影响，保留原行（保持原始空格/格式）
        new_lines.append(orig_line + '\n')

# 重新插入地址行
output_lines = []
addr_idx = 0
byte_cursor = 0

for i, (start, end, orig_line) in enumerate(data_line_ranges):
    # 插入地址行（如果有的话）
    while addr_idx < len(addr_lines) and addr_lines[addr_idx][0] <= byte_cursor:
        output_lines.append(addr_lines[addr_idx][1] + '\n')
        addr_idx += 1
    output_lines.append(new_lines[i])
    byte_cursor = end

# 插入剩余地址行（如果有）
while addr_idx < len(addr_lines):
    output_lines.append(addr_lines[addr_idx][1] + '\n')
    addr_idx += 1

# 写回文件
with open(hex_file, 'w', encoding='ascii') as fp:
    fp.writelines(output_lines)

# print(f"Successfully replaced placeholder at byte offset {found_offset} in {hex_file}")
