import Foundation

/// Když je zapnuto, text se po diktování neposílá automaticky do cílové aplikace — přepis se zkopíruje do schránky a zobrazí v historii.
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
