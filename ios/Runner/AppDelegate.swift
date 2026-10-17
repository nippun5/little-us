import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var fridgeChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "LittleUsFridgeWidget") {
      let channel = FlutterMethodChannel(name: "little_us/fridge_widget", binaryMessenger: registrar.messenger())
      fridgeChannel = channel
      channel.setMethodCallHandler { call, result in
        if call.method == "requestPin" { result(false); return }
        guard call.method == "update" else { result(FlutterMethodNotImplemented); return }
        // Configure this key in Runner AND the widget extension's Info.plist.
        guard let group = Bundle.main.object(forInfoDictionaryKey: "LittleUsAppGroup") as? String,
              FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) != nil,
              let defaults = UserDefaults(suiteName: group) else {
          let enabled = (call.arguments as? [String: Any])?["enabled"] as? Bool ?? false
          if !enabled { result(nil); return }
          result(FlutterError(code: "APP_GROUP", message: "Configure the shared LittleUsAppGroup entitlement in Xcode.", details: nil)); return
        }
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "BAD_ARGS", message: "Missing widget data", details: nil)); return
        }
        let enabled = args["enabled"] as? Bool ?? false
        let snapshot: [String: Any] = [
          "enabled": enabled,
          "body": enabled ? String((args["body"] as? String ?? "").prefix(500)) : "",
          "author": enabled ? String((args["author"] as? String ?? "Little us").prefix(30)) : "",
          "updatedAt": enabled ? (args["updatedAt"] as? NSNumber ?? 0) : 0,
          "demo": enabled && (args["demo"] as? Bool ?? false)
        ]
        // One atomic preference value. Never share the auth session with WidgetKit.
        defaults.set(snapshot, forKey: "fridge_snapshot")
        if #available(iOS 14.0, *) { WidgetCenter.shared.reloadTimelines(ofKind: "LittleUsFridgeWidget") }
        result(nil)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
