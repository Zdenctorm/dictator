import Foundation

/// První úspěšný přepis — skryje nápovědu v hlavním okně.
enum OnboardingPreference {
    private static let completedFirstDictationKey = "locute.onboarding.completedFirstDictation"

    static var completedFirstDictation: Bool {
        get { UserDefaults.standard.bool(forKey: completedFirstDictationKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedFirstDictationKey) }
    }
}
