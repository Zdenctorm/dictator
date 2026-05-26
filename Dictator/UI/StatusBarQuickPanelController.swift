import AppKit

@MainActor
final class StatusBarQuickPanelController: NSObject, NSPopoverDelegate {
    private let popover = NSPopover()
    private let stateLabel = NSTextField(labelWithString: "")
    private let hintLabel = NSTextField(wrappingLabelWithString: "")
    private let entriesStack = NSStackView()
    private let emptyEntriesLabel = AppTheme.label(
        "Zatím žádný přepis. Podrž diktovací klávesu a mluv.",
        font: AppTheme.Font.body,
        color: AppTheme.Color.body,
        lines: 0
    )

    private var onOpenHistory: (() -> Void)?
    private var onOpenSettings: (() -> Void)?

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.dateFormat = "d. M., HH:mm"
        return formatter
    }()

    override init() {
        super.init()
        popover.behavior = .transient
        popover.delegate = self
        popover.contentSize = NSSize(width: 380, height: 420)
        let controller = NSViewController()
        controller.view = buildContent()
        popover.contentViewController = controller
    }

    func show(
        relativeTo button: NSStatusBarButton,
        state: DictatorState,
        recentEntries: [TranscriptionHistoryEntry],
        onOpenHistory: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.onOpenHistory = onOpenHistory
        self.onOpenSettings = onOpenSettings

        stateLabel.stringValue = state.displayText
        hintLabel.stringValue = Self.hintLine(for: state)
        rebuildEntries(Array(recentEntries.prefix(3)))

        if popover.isShown {
            popover.performClose(nil)
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func close() {
        popover.performClose(nil)
    }

    private func rebuildEntries(_ entries: [TranscriptionHistoryEntry]) {
        for view in entriesStack.arrangedSubviews {
            entriesStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        guard !entries.isEmpty else {
            emptyEntriesLabel.isHidden = false
            return
        }

        emptyEntriesLabel.isHidden = true
        for (index, entry) in entries.enumerated() {
            let row = QuickPanelEntryRow(
                title: Self.truncatedTitle(entry.text),
                subtitle: Self.dateFormatter.string(from: entry.recordedAt)
            )
            entriesStack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: entriesStack.widthAnchor).isActive = true

            if index < entries.count - 1 {
                let separator = NSBox()
                separator.boxType = .separator
                separator.translatesAutoresizingMaskIntoConstraints = false
                entriesStack.addArrangedSubview(separator)
                separator.widthAnchor.constraint(equalTo: entriesStack.widthAnchor).isActive = true
            }
        }
    }

    private func buildContent() -> NSView {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 420))
        root.wantsLayer = true
        AppTheme.applyPanelChrome(to: root)

        stateLabel.font = AppTheme.Font.status
        stateLabel.textColor = AppTheme.Color.title
        AccessibilitySupport.configure(stateLabel, label: "Stav")

        hintLabel.font = AppTheme.Font.footnote
        hintLabel.textColor = AppTheme.Color.body
        hintLabel.maximumNumberOfLines = 3
        hintLabel.lineBreakMode = .byWordWrapping
        AccessibilitySupport.configure(hintLabel, label: "Nápověda")

        let recentTitle = AppTheme.label(
            "Poslední přepisy",
            font: AppTheme.Font.headline,
            color: AppTheme.Color.title
        )

        entriesStack.orientation = .vertical
        entriesStack.alignment = .leading
        entriesStack.spacing = AppTheme.Spacing.tight
        entriesStack.translatesAutoresizingMaskIntoConstraints = false

        emptyEntriesLabel.translatesAutoresizingMaskIntoConstraints = false

        let historyButton = AppTheme.secondaryButton("Historie…", target: self, action: #selector(openHistory))
        let settingsButton = AppTheme.secondaryButton("Nastavení…", target: self, action: #selector(openSettings))
        let footerButtons = NSStackView(views: [historyButton, settingsButton])
        footerButtons.orientation = .horizontal
        footerButtons.spacing = AppTheme.Spacing.row

        let stack = NSStackView(views: [
            stateLabel,
            hintLabel,
            recentTitle,
            emptyEntriesLabel,
            entriesStack,
            footerButtons
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = AppTheme.Spacing.row
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(AppTheme.Spacing.tight, after: stateLabel)
        stack.setCustomSpacing(AppTheme.Spacing.section, after: hintLabel)
        stack.setCustomSpacing(AppTheme.Spacing.tight, after: recentTitle)

        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: root.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: root.bottomAnchor, constant: -16),

            hintLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            entriesStack.widthAnchor.constraint(equalTo: stack.widthAnchor),
            emptyEntriesLabel.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        return root
    }

    @objc private func openHistory() {
        onOpenHistory?()
        close()
    }

    @objc private func openSettings() {
        onOpenSettings?()
        close()
    }

    private static func truncatedTitle(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 72 else { return trimmed.isEmpty ? "Prázdný přepis" : trimmed }
        return String(trimmed.prefix(69)) + "…"
    }

    private static func hintLine(for state: DictatorState) -> String {
        switch state {
        case .idle:
            return "Podrž \(HotkeyPreference.current.hintLabel) nebo klepni na ikonu pro rychlý náhled."
        case .recording:
            return "Nahrávám — pusť klávesu nebo ukonči z menu."
        case .modelDownloading, .modelLoading, .launching:
            return "Po dokončení přípravy modelu půjde diktovat klávesou \(HotkeyPreference.current.hintLabel)."
        case .transcribing:
            return "Přepisuji lokálně — chvíli strpení."
        case .injecting:
            return "Vkládám text do aktivního pole."
        case .permissionsNeeded:
            return "Doplň oprávnění mikrofon a Zpřístupnění v Nastavení."
        case .error:
            return "Je potřeba zásah — otevři Nastavení nebo diagnostické logy."
        }
    }
}

// MARK: - Entry row

@MainActor
private final class QuickPanelEntryRow: NSView {
    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = AppTheme.label(title, font: AppTheme.Font.body, color: AppTheme.Color.title, lines: 2)
        let subtitleLabel = AppTheme.label(subtitle, font: AppTheme.Font.footnote, color: AppTheme.Color.body)

        let textStack = NSStackView(views: [titleLabel, subtitleLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textStack)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            textStack.topAnchor.constraint(equalTo: topAnchor),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: textStack.widthAnchor),
            subtitleLabel.widthAnchor.constraint(lessThanOrEqualTo: textStack.widthAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
