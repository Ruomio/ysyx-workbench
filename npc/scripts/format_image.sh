#!/bin/env bash
BIN_FILE="$1"
HEX_FILE="$2"
LOAD_ADDR="${3:-00000000}"  # 默认 0x00000000

if [ -z "$BIN_FILE" ] || [ -z "$HEX_FILE" ]; then
    echo "Usage: $0 <input.bin> <output.hex> [load_addr_hex]"
    exit 1
fi

echo "@$LOAD_ADDR" > "$HEX_FILE"
# od -t x1 -v -An "$BIN_FILE" | awk '{for(i=1;i<=NF;i++) if($i!="") print $i}' >> "$HEX_FILE"
od -t x1 -v -An "$BIN_FILE" | tr -s ' ' '\n' | grep -v '^$' | \
awk '{
    printf "%s%s", $0, (NR % 16 == 0) ? "\n" : " "
}
END {
    if (NR % 16 != 0) printf "\n"
}' >> "$HEX_FILE"

echo "✅ 生成: $HEX_FILE (加载地址: 0x$LOAD_ADDR)"
# head -5 "$HEX_FILE"