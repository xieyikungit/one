import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: Self.isEnglish ? "Follow System" : "跟随系统"
        case .simplifiedChinese: "简体中文"
        case .english: "English"
        }
    }
    var locale: Locale {
        self == .system ? Locale.current : Locale(identifier: rawValue)
    }
    static var current: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? "system") ?? .system
    }
    static var isEnglish: Bool {
        current.locale.language.languageCode?.identifier == "en"
    }
    static func localized(_ key: String) -> String {
        guard isEnglish,
              let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
              let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: localized(key), locale: current.locale, arguments: arguments)
    }
}

enum AppDate {
    static func yearMonthDay(_ date: Date) -> String {
        if AppLanguage.isEnglish {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}
