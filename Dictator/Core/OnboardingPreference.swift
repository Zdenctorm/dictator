import Foundation

enum OnboardingPreference {
    private static let hasCompletedKey = "hasCompletedOnboarding"
    private static let suppressAutoLaunchKey = "suppressAutoLaunchWindow"

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedKey) }
    }

    /// Po dokončení průvodce výchozí `true` — hlavní okno se neotevře automaticky.
    static var suppressAutoLaunchWindow: Bool {
        get {
            if UserDefaults.standard.object(forKey: suppressAutoLaunchKey) == nil {
                return hasCompletedOnboarding
            }
            return UserDefaults.standard.bool(forKey: suppressAutoLaunchKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: suppressAutoLaunchKey) }
    }

    static func markOnboardingComplete() {
        hasCompletedOnboarding = true
        suppressAutoLaunchWindow = true
    }
}
