#!/bin/bash

# =================================================================
# 配置区
# =================================================================
API_URL="http://localhost:8081/engine/api/v1/mdm/upload/file"

# =================================================================
# 入参检查
# =================================================================

# 检查参数个数
if [ "$#" -lt 2 ]; then
    echo "用法: $0 <场景ID> <本地文件路径> [远程文件名]"
    echo "示例: $0 1001 ./test.yaml my_config.yaml"
    exit 1
fi

SCENE_ID=$1
LOCAL_FILE=$2
# 如果没有提供第三个参数，则默认使用本地文件的文件名
REMOTE_FILENAME=${3:-$(basename "$LOCAL_FILE")}

# 1. 检查本地文件是否存在
if [ ! -f "$LOCAL_FILE" ]; then
    echo "错误: 找不到本地文件 '$LOCAL_FILE'"
    exit 1
fi

# 2. 检查场景ID是否为数字 (基于你的应用逻辑，通常ID为数字或字母组合)
if [[ ! $SCENE_ID =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "错误: 场景ID '$SCENE_ID' 格式不正确 (仅限字母、数字、下划线和连字符)"
    exit 1
fi

echo "正在上传..."
echo "-----------------------------------"
echo "场景ID:   $SCENE_ID"
echo "本地路径: $LOCAL_FILE"
echo "远程名称: $REMOTE_FILENAME"
echo "-----------------------------------"

# =================================================================
# 执行上传
# =================================================================

# 使用 curl 发送 POST 请求
# -F "sceneId=..." 对应 Java 中的 @RequestParam("sceneId")
# -F "fileName=..." 对应 Java 中的 @RequestParam("fileName")
RESPONSE=$(curl -s -X POST "$API_URL" \
  -F "file=@$LOCAL_FILE" \
  -F "sceneId=$SCENE_ID" \
  -F "fileName=$REMOTE_FILENAME")

# 检查 curl 执行状态
if [ $? -ne 0 ]; then
    echo "错误: 无法连接到服务器 $API_URL"
    exit 1
fi

# 解析结果 (假设你安装了 jq)
SUCCESS_MSG=$(echo "$RESPONSE" | jq -r '.message // "Error"')
MY_URL=$(echo "$RESPONSE" | jq -r '.url // "null"')
VERSION=$(echo "$RESPONSE" | jq -r '.versionNumber // "unknown"')

if [ "$SUCCESS_MSG" == "Upload Success" ]; then
    echo "✅ 上传成功！"
    echo "版本号: $VERSION"
    echo "访问地址: $MY_URL"
else
    echo "❌ 上传失败！服务器返回:"
    echo "$RESPONSE"
    exit 1
fi
