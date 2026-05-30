import AppKit

/// Jednoduchý level meter pro HUD při nahrávání (posledních N vzorků).
final class RecordingLevelMeterView: NSView {
    private var levels: [CGFloat] = Array(repeating: 0.05, count: 24)
    private let barCount: Int

    init(barCount: Int = 24) {
        self.barCount = barCount
        self.levels = Array(repeating: 0.05, count: barCount)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        AccessibilitySupport.configure(self, label: "Hlasitost mikrofonu", hidden: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func pushLevel(_ normalized: Float) {
        let clamped = CGFloat(min(1, max(0, normalized)))
        levels.removeFirst()
        levels.append(max(0.06, clamped))
        needsDisplay = true
    }

    func reset() {
        levels = Array(repeating: 0.05, count: barCount)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let barWidth: CGFloat = 3
        let gap: CGFloat = 2
        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * gap
        var x = (bounds.width - totalWidth) / 2
        let maxHeight = bounds.height

        for level in levels {
            let height = max(2, level * maxHeight)
            let rect = CGRect(x: x, y: (maxHeight - height) / 2, width: barWidth, height: height)
            ctx.setFillColor(AppTheme.Color.recording.withAlphaComponent(0.85).cgColor)
            ctx.fill(rect)
            x += barWidth + gap
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: CGFloat(barCount) * 5 + 20, height: 18)
    }
}
