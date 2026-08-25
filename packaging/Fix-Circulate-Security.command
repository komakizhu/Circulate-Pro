#!/bin/bash
set -euo pipefail

echo "Circulate Pro 安全提示修复"
echo "此脚本只处理 Circulate Pro 插件的下载隔离标记，不修复实际损坏的文件。"
echo "它将请求管理员权限，并只检查以下两个精确路径："
echo "  /Library/Audio/Plug-Ins/VST3/Circulate.vst3"
echo "  /Library/Audio/Plug-Ins/Components/Circulate.component"
echo

for plugin_path in \
    "/Library/Audio/Plug-Ins/VST3/Circulate.vst3" \
    "/Library/Audio/Plug-Ins/Components/Circulate.component"; do
    if [[ -e "${plugin_path}" ]]; then
        echo "处理：${plugin_path}"
        sudo /usr/bin/xattr -dr com.apple.quarantine "${plugin_path}" || true
    else
        echo "未找到：${plugin_path}"
    fi
done

/usr/bin/killall -q AudioComponentRegistrar 2>/dev/null || true
echo
echo "完成。请重新启动 Logic Pro 或其他宿主后再扫描插件。"
read -r -p "按回车退出。" _
