import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var effectsPlayer: AVAudioPlayer?
  private var effectName: String?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NoorEffects") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "dev.noor.noor/speech", binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "effect",
        let name = call.arguments as? String,
        ["tap", "correct", "retry", "complete"].contains(name)
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      let asset = registrar.lookupKey(forAsset: "assets/audio/noor_\(name).wav")
      if let path = Bundle.main.path(forResource: asset, ofType: nil) {
        self?.playEffect(name, at: URL(fileURLWithPath: path))
      }
      result(nil)
    }
    NotificationCenter.default.addObserver(
      self, selector: #selector(stopEffects),
      name: UIApplication.willResignActiveNotification, object: nil
    )
  }

  private func playEffect(_ name: String, at url: URL) {
    if name == "tap", effectName != "tap", effectsPlayer?.isPlaying == true {
      return
    }
    do {
      try AVAudioSession.sharedInstance().setCategory(.ambient)
      let next = try AVAudioPlayer(contentsOf: url)
      effectsPlayer?.stop()
      effectsPlayer = next
      effectName = name
      next.play()
    } catch {
      // Offline effects are optional.
    }
  }

  @objc private func stopEffects() {
    effectsPlayer?.stop()
  }
}
