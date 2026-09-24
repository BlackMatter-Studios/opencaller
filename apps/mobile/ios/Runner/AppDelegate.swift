import CallKit
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  private let EXTENSION_ID = "cc.blackmatter.opencaller.OpenCallerDirectoryExtension"
  private let APP_GROUP_ID = "group.cc.blackmatter.opencaller"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    if let messenger = controller?.binaryMessenger {
      setupCallKitChannel(messenger: messenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    setupCallKitChannel(messenger: engineBridge.binaryMessenger)
  }

  private func setupCallKitChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "cc.blackmatter.opencaller/callkit", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }

      switch call.method {
      case "reloadExtension":
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: self.EXTENSION_ID) { error in
          DispatchQueue.main.async {
            if let error = error {
              NSLog("Error reloading Call Directory extension: \(error.localizedDescription)")
              result(FlutterError(code: "RELOAD_FAILED", message: error.localizedDescription, details: nil))
            } else {
              NSLog("Successfully reloaded Call Directory extension")
              result(true)
            }
          }
        }

      case "getExtensionStatus":
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: self.EXTENSION_ID) { (status, error) in
          DispatchQueue.main.async {
            if let error = error {
              NSLog("Error checking extension status: \(error.localizedDescription)")
              result(0) // Unknown
            } else {
              // 0: Unknown, 1: Disabled, 2: Enabled
              result(status.rawValue)
            }
          }
        }

      case "getAppGroupDirectory":
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.APP_GROUP_ID) {
          result(containerURL.path)
        } else {
          result(nil)
        }

      case "openSettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            result(true)
          } else {
            result(false)
          }
        } else {
          result(false)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
