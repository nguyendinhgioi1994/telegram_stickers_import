import Flutter
import UIKit
import TelegramStickersImport

public class SwiftTelegramStickersImportPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "telegram_stickers_import", binaryMessenger: registrar.messenger())
        let instance = SwiftTelegramStickersImportPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method=="import"){
            handleImport(call:call, result:result)
        }else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleImport(call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            let args = call.arguments as! Dictionary<String, Any?>
            
            let software = args["software"] as! String
            let isAnimated = args["isAnimated"] as! Bool
            let rawStickers = args["stickers"] as! [Dictionary<String, Any?>]
            
            let stickerSetType: StickerSet.StickerSetType = isAnimated ? .animated : .static
            let stickerSet = StickerSet(software: software, type: stickerSetType)
            
            for sticker in rawStickers {
                let data = convertStickerData(input: sticker["data"] as! Dictionary<String, Any?>)
                let emojis = sticker["emojis"] as! [String]
                try stickerSet.addSticker(data: stickerSetType == .animated ? .animation(data) : .image(data), emojis: emojis)
            }
            
            if let thumbnail = args["thumbnail"] as? Dictionary<String, Any?> {
                let data = convertStickerData(input: thumbnail["data"] as! Dictionary<String, Any?>)
                try stickerSet.setThumbnail(data: .image(data))
            }
            
            try stickerSet.import()
        } catch let error as StickersError {
            var errorCode: String
            switch error {
                case .fileTooBig:
                    errorCode = "1"
                case .invalidDimensions:
                    errorCode = "2"
                case .countLimitExceeded:
                    errorCode = "3"
                case .dataTypeMismatch:
                    errorCode = "4"
                case .setIsEmpty:
                    errorCode = "5"
            }
            result(FlutterError(code: errorCode, message: "error while import", details: error.localizedDescription))
        } catch {
            result(FlutterError(code: "6", message: "error while import", details: error.localizedDescription))
        }
        result("success")
    }
    
    private func convertStickerData(input: Dictionary<String, Any?>) -> Data {
        let uintInt8List =  input["bytes"] as! FlutterStandardTypedData
        let bytes = [UInt8](uintInt8List.data)
        return Data(bytes)
    }
}
