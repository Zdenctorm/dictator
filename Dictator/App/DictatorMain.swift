import Cocoa

@main
struct DictatorMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()

        app.delegate = delegate
        AppAppearancePreference.applyActivationPolicy()
        app.run()
    }
}
