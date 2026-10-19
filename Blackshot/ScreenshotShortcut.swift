import Foundation
import Carbon.HIToolbox

struct ScreenshotShortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    var keyLabel: String
    static let standard = ScreenshotShortcut(keyCode: UInt32(kVK_ANSI_6), modifiers: UInt32(cmdKey | shiftKey), keyLabel: "6")
    var display: String {
        (modifiers & UInt32(optionKey) != 0 ? "⌥" : "") +
        (modifiers & UInt32(shiftKey) != 0 ? "⇧" : "") + "⌘" + keyLabel
    }
    var isValid: Bool {
        let allowed = UInt32(cmdKey | shiftKey | optionKey)
        return modifiers & UInt32(cmdKey) != 0 && modifiers & ~allowed == 0 && keyCode <= 127 && !keyLabel.isEmpty
    }
}

