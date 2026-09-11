import Flutter
import UIKit

/// Glean iCloud Drive 通道（B 档云盘同步）：
/// 备份文件写入用户 iCloud 容器的 Documents/backup.json（用户配额，服务器零存储）。
/// 需要 Xcode → Signing & Capabilities → + iCloud → 勾选「iCloud Documents」。
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let registry = engineBridge.pluginRegistry
    GeneratedPluginRegistrant.register(with: registry)

    // —— iCloud Drive 通道 ——
    // registrar(forPlugin:) 返回 optional：对自定义通道名会创建 registrar，强制解包
    let messenger: FlutterBinaryMessenger = registry.registrar(forPlugin: "GleanICloud")!
      .messenger()
    let channel = FlutterMethodChannel(
      name: "glean/icloud", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
        if call.method == "isAvailable" {
          result(false)
        } else {
          result(FlutterError(code: "ICLOUD_UNAVAILABLE",
                              message: "iCloud 未启用或未登录", details: nil))
        }
        return
      }
      let dir = container.appendingPathComponent("Documents", isDirectory: true)
      try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      let file = dir.appendingPathComponent("backup.json")

      switch call.method {
      case "isAvailable":
        result(true)
      case "backupExists":
        result(FileManager.default.fileExists(atPath: file.path))
      case "upload":
        guard let content = call.arguments as? String else {
          result(FlutterError(code: "BAD_ARG", message: "content required", details: nil))
          return
        }
        do {
          try content.write(to: file, atomically: true, encoding: .utf8)
          result(true)
        } catch {
          result(FlutterError(code: "WRITE_FAIL", message: error.localizedDescription, details: nil))
        }
      case "download":
        result(try? String(contentsOf: file, encoding: .utf8))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}