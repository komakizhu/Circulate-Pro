@PRODUCT_NAME@ macOS Universal 安装包
================================

版本：@VERSION@
格式：VST3 + AUv2
架构：Universal 2（Apple Silicon arm64 + Intel x86_64）
最低系统：macOS 11.0

本 DMG 顶层包含四项：README、安装 PKG、Copyright 文件夹和卸载程序。Copyright 文件夹
内含 GPL-3.0 许可证以及源码与修改说明。

安装
----
双击“2 Install @PRODUCT_NAME@.pkg”，按 Installer 提示授权。在“安装类型”页面点击
“自定义”，可分别勾选 VST3 Plug-in 和 AUv2 Plug-in；默认两项都会选中。插件会安装到：

  /Library/Audio/Plug-Ins/VST3/Circulate.vst3
  /Library/Audio/Plug-Ins/Components/Circulate.component

安装完成后重启 Logic Pro、Ableton Live 或其他宿主，再扫描插件。

卸载
----
双击“4 @PRODUCT_NAME@ Uninstaller.app”，确认后输入管理员密码。它只删除 Circulate 的
两个插件和安装收据，不删除工程、预设或其他厂商插件。

安全提示
--------
本版本没有 Apple Developer ID 签名或公证。若 macOS 显示“无法验证开发者”或
“无法打开，因为无法验证开发者”，请先在 Finder 中右键该项目并选择“打开”，
或到“系统设置 > 隐私与安全性”允许本次打开。

这只是 macOS 的下载安全提示处理方式，不修复实际损坏的文件，也不替代 Developer ID
签名和公证。打开前请确认文件来自可信来源。

正式公开发行
------------
正式发行应使用 Developer ID Application 签名插件与卸载 App、Developer ID Installer
签名 PKG，并提交 Apple notarization。发布脚本支持以下环境变量：

  CIRCULATE_DEVELOPER_ID_APPLICATION
  CIRCULATE_DEVELOPER_ID_INSTALLER
  CIRCULATE_NOTARY_PROFILE

许可证和源码
------------
Circulate 按 GPL-3.0 发布。请阅读“3 Copyright/GPL-3.0-License.txt”，并从以下地址获取源码和
本 macOS 兼容修改：

  3.0.0 adds knob double-click reset, corrects the Note and Depth factory defaults,
  supports approximately 10x fine knob adjustment while holding Shift during a drag,
  and adds nine independent stepped keyframes from the supplied 3x3 raster sheet.
  The supplied head/body changes are preserved; each complete bird is moved upward
  so its original leg is visible, and the leg stays behind the Depth value box.
  Each source image is held for eight Depth values: 0-7, 8-15, through 56-63;
  Depth 64 selects the ninth image. The runtime jumps directly between the nine
  source images, without path redraw, interpolation, whole-image overlay,
  opacity fading or animation, and links the macOS version credit to the fork.

  macOS fork source and modifications:
  https://github.com/komakizhu/Circulate-VST-macOS

  Upstream source:
  https://github.com/GullDSP/Circulate-VST
