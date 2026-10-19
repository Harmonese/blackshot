import Combine
import Foundation

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    enum Language: String {
        case chinese = "zh-Hans"
        case english = "en"
        var displayName: String { self == .chinese ? "中文" : "English" }
    }
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "AppLanguage"), let language = Language(rawValue: saved) {
            currentLanguage = language
        } else {
            currentLanguage = (Locale.preferredLanguages.first ?? "en").hasPrefix("zh") ? .chinese : .english
        }
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("LanguageChanged")
}

@MainActor
func L(_ chinese: String, _ english: String) -> String {
    LanguageManager.shared.currentLanguage == .chinese ? chinese : english
}
