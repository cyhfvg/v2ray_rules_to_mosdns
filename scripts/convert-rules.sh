#!/bin/bash
set -e # 遇到错误立即退出

# 转换 geosite 类别函数
convert_geosite_category() {
    local category="$1"
    echo "Converting geosite category: $category"
    ./temp/mosdns v2dat unpack-domain -o rules "temp/geosite.dat:$category"
    # 重命名文件
    mv "rules/geosite_${category}.txt" "data/geosite_${category}.txt"
}

# 要转换的类别列表
categories=(
    "apple-cn"
    "icloud"
    "google-cn"
    "tld-cn"
    "cn"
)

# 清理并创建规则目录
mkdir -p rules

# 执行转换 geosite
for category in "${categories[@]}"; do
    convert_geosite_category "$category"
done

echo "Conversion completed. Files are stored in the 'rules' directory."
