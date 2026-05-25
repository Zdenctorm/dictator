import Cocoa
import Foundation

enum AppAppearancePreference {
    private static let showInDockKey = "showInDock"

    /// Výchozí: skrýt ikonu v Docku (čistá menu bar appka).
    static var showInDock: Bool {
        get {
            if UserDefaults.standard.object(forKey: showInDockKey) == nil {
                return false
            }
            return UserDefaults.standard.bool(forKey: showInDockKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: showInDockKey)
            applyActivationPolicy()
            NotificationCenter.default.post(name: .dictatorAppearancePreferenceChanged, object: nil)
        }
    }

    static func applyActivationPolicy() {
        let app = NSApplication.shared
        if showInDock {
            app.setActivationPolicy(.regular)
        } else {
            app.setActivationPolicy(.accessory)
        }
    }
}

extension Notification.Name {
    static let dictatorAppearancePreferenceChanged = Notification.Name("DictatorAppearancePreferenceChanged")
}
