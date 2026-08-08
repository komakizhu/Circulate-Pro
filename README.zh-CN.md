# Circulate

[English](README.md) | [中文](README.zh-CN.md)

> **Fork / macOS 版本说明：** 本仓库是 [GullDSP/Circulate-VST](https://github.com/GullDSP/Circulate-VST) 的 macOS fork。插件版本基线为 Circulate 2.0.0，源代码基于上游 commit `65236c9`（原仓库中的 `v2.0.1.1`）。本 fork 增加了 Intel 与 Apple Silicon 通用的 Universal 2 VST3/AUv2 构建，以及 macOS PKG/DMG 打包支持；原有 DSP 算法和界面保持不变。

Circulate 是一款基于全通滤波器的相位扩散效果器。全通滤波器不改变频谱幅度，但会在选定中心频率附近产生选择性的相位偏移，从而形成空洞、金属感和短混响般的听感。该效果在贝斯 Stab、鼓击和 Pluck 等瞬态素材上最明显。

## 下载

### macOS Universal 2

[PKG / DMG 发布页](https://github.com/komakizhu/Circulate-VST-macOS/releases)，支持 Intel 与 Apple Silicon。

### Windows 原版

[下载 circulate-vst3-v2_0_1.zip](https://github.com/GullDSP/Circulate-VST/releases/download/v2.0.1.1/circulate-vst3-v2_0_1.zip)（上游 `v2.0.1.1`）。这是真正的 Windows 原版构建，来源于上游项目。

### `.dmg.sha256` 是什么？

它是 DMG 安装包的 SHA-256 校验值文件，用来确认下载是否完整，以及文件在传输或存储过程中是否被损坏或篡改。macOS 可在终端运行 `shasum -a 256 Circulate-macOS-2.0.0-Universal.dmg`，将输出结果与该文件中的值进行比较；两者一致即可。

当前 macOS 发布包包含 Universal 2 VST3、AUv2、安装 PKG、卸载程序和版权材料。未配置 Developer ID 与公证的版本可能触发 macOS Gatekeeper 提示，详见发布包中的 README。

## 功能

- 参数与自动化支持采样精度，适合快速、复杂的 DAW 自动化和调制器控制，例如 Ableton LFO。
- 最多 64 级全通滤波器，支持可变 Q 值（共振）。
- 中心频率可直接用 Hz 控制，也可通过 MIDI 音符选择。
- 支持滤波器组正反馈或负反馈，用于产生类似陡峭移相器的频谱效果。

## 参数

- **Center**：全通滤波器中心频率，单位 Hz；点击数值可手动输入精确值。
- **Pitch**：通过 MIDI 音符设置中心频率。
- **Det**：在所选 MIDI 音符的基础上平滑偏移中心频率，范围为 ±1 个八度。
- **Focus**：全通滤波器的 Q 值，即“共振”。低 Q 会使相位扩散覆盖更宽频段，高 Q 会使其集中在中心频率附近。
- **Depth**：滤波器组中的全通滤波器数量，最多 64 级。
- **Feed**：向滤波器组引入反馈，会通过频率抵消或增强改变频谱。

## Version 2

- 支持调整界面大小（右键菜单 → UI Zoom）。
- 降低 CPU 使用率。
- 修复 Ableton 中 Hz 与半音控制切换时的界面问题。
- 修复部分 DAW 中导出音频时的异常行为。
- 支持手动输入 Hz 频率。

## 构建 macOS 插件

项目通过 Git 子模块包含 Steinberg VST 3 SDK 和 Apple AudioUnitSDK，可构建同时支持 Intel 与 Apple Silicon 的 Universal 2 VST3 和 AUv2 bundle。

```bash
git clone --recurse-submodules https://github.com/komakizhu/Circulate-VST-macOS.git
cd Circulate-VST-macOS
cmake -S . -B build-macos -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
  -DSMTG_ENABLE_VSTGUI_SUPPORT=ON \
  -DSMTG_CREATE_PLUGIN_LINK=OFF
cmake --build build-macos -j1
```

VST3 bundle 输出在 `build-macos/VST3/Release/Circulate.vst3`。构建 AUv2 时使用 Xcode generator，并启用 `CIRCULATE_ENABLE_AUV2`：

```bash
cmake -S . -B build-macos-au -G Xcode \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
  -DSMTG_ENABLE_VSTGUI_SUPPORT=ON \
  -DSMTG_CREATE_PLUGIN_LINK=OFF \
  -DCIRCULATE_ENABLE_AUV2=ON \
  -DCIRCULATE_AUV2_STAGING_DIR="$PWD/outputs"
cmake --build build-macos-au --config Release
```

当两个 bundle 都位于 `outputs/` 后，运行 `packaging/build-release.sh` 可生成 Universal 2 PKG 和 DMG。PKG 安装目标为系统级音频插件目录。

## 许可与致谢

本项目遵循 GPL-3.0。重新发布修改后的二进制时，请同时提供许可证、上游来源和本 fork 的修改说明。

项目使用 [Steinberg VST 3 SDK](https://www.steinberg.net/developers/)。VST 是 Steinberg Media Technologies GmbH 的商标。

上游项目：[GullDSP/Circulate-VST](https://github.com/GullDSP/Circulate-VST)
