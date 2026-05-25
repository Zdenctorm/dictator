import Foundation

/// Když je zapnuto, externí vložení textu vyžaduje potvrzení v okně Dictatoru (Aqua-style review).
enum DictationReviewPreference {
    private static let storageKey = "reviewBeforePaste"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: storageKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: storageKey)
            NotificationCenter.default.post(name: .dictatorReviewPreferenceChanged, object: nil)
        }
    }
}

extension Notification.Name {
    static let dictatorReviewPreferenceChanged = Notification.Name("DictatorReviewPreferenceChanged")
}
