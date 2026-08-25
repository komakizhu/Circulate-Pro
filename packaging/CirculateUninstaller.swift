import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "卸载 Circulate Pro"
        alert.informativeText = "这将移除系统级安装的 Circulate Pro VST3 和 AUv2 插件。Logic/Ableton 工程、用户预设及其他插件不会被删除。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "卸载")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            uninstall()
        } else {
            NSApp.terminate(nil)
        }
    }

    private func uninstall() {
        guard let scriptPath = Bundle.main.path(forResource: "uninstall-root", ofType: "sh") else {
            showResult(title: "无法卸载", message: "找不到卸载脚本。请重新下载完整 DMG。", terminate: true)
            return
        }

        let escapedPath = scriptPath
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let appleScript = "do shell script \"/bin/sh \" & quoted form of \"\(escapedPath)\" with administrator privileges"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                showResult(title: "卸载完成", message: "Circulate Pro 的系统级 VST3 和 AUv2 插件已移除。", terminate: true)
            } else {
                showResult(title: "卸载未完成", message: "管理员授权被取消，或卸载脚本执行失败。", terminate: true)
            }
        } catch {
            showResult(title: "卸载失败", message: error.localizedDescription, terminate: true)
        }
    }

    private func showResult(title: String, message: String, terminate: Bool) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "好")
        alert.runModal()
        if terminate { NSApp.terminate(nil) }
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
