import Foundation

struct L10n {
    static func t(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}
