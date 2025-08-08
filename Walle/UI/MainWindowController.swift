//
//  MainWindowController.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import AppKit
import SwiftData

final class MainWindowController: NSWindowController, NSToolbarDelegate {
    private let splitVC: NSSplitViewController
    private let sidebarVC: SidebarViewController
    private let previewVC: PreviewPaneViewController

    private let bottomBar = NSVisualEffectView()

    private let modelContext: ModelContext
    private let coordinator: WallpaperCoordinator

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.coordinator = WallpaperCoordinator(modelContext: modelContext)
        self.sidebarVC = SidebarViewController(modelContext: modelContext)
        self.previewVC = PreviewPaneViewController()
        self.splitVC = NSSplitViewController()
        super.init(window: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(handleImportURL(_:)), name: .importURL, object: nil)

        sidebarVC.onSelect = { [weak self] model in
            guard let url = model.localFileURL else { return }
            self?.previewVC.configure(with: url, title: model.title)
        }
        previewVC.onApply = { [weak self] url, mode in
            switch mode { case .fit: WallpaperRenderer.shared.setAspect(.fit); case .fill: WallpaperRenderer.shared.setAspect(.fill); case .original: WallpaperRenderer.shared.setAspect(.original) }
            self?.coordinator.apply(url: url)
            self?.sidebarVC.reload() // reflect applied state
        }

        setupWindow()
        setupToolbar()

        // Set default aspect
        let prefs = PreferencesStore.load()
        switch prefs.defaultAspect {
        case .fit: WallpaperRenderer.shared.setAspect(.fit)
        case .fill: WallpaperRenderer.shared.setAspect(.fill)
        case .original: WallpaperRenderer.shared.setAspect(.original)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupWindow() {
        let contentView = NSVisualEffectView()
        contentView.state = .active
        contentView.material = .underWindowBackground
        contentView.blendingMode = .behindWindow

        let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 620),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        win.isOpaque = false
        win.title = "Walle"
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.contentView = contentView
        win.center()
        self.window = win

        let left = NSSplitViewItem(sidebarWithViewController: sidebarVC)
        left.minimumThickness = 240
        left.preferredThicknessFraction = 0.33
        let right = NSSplitViewItem(viewController: previewVC)
        splitVC.addSplitViewItem(left)
        splitVC.addSplitViewItem(right)
        splitVC.splitView.isVertical = true
        splitVC.view.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(splitVC.view)
        contentView.addSubview(bottomBar)

        bottomBar.material = .sidebar
        bottomBar.state = .active
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            splitVC.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            splitVC.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            splitVC.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            splitVC.view.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Bottom bar content
        let importButton = NSButton(title: "Import Local…", target: self, action: #selector(importLocal))
        let progressLabel = NSTextField(labelWithString: "Idle")
        progressLabel.textColor = .secondaryLabelColor
        let gearImage = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings") ?? NSImage()
        let gearButton = NSButton(image: gearImage, target: self, action: #selector(openPreferences))
        gearButton.isBordered = false

        let stack = NSStackView(views: [importButton, NSView(), progressLabel, gearButton])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -12),
            stack.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor)
        ])
    }

    private func setupToolbar() {
        guard let window else { return }
        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.centeredItemIdentifier = .search
        window.toolbar = toolbar
    }

    // MARK: Toolbar
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.search, .flexibleSpace, .apply, .launchToggle, .importItem]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.search, .flexibleSpace, .apply, .launchToggle, .importItem]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .search:
            let item = NSSearchToolbarItem(itemIdentifier: .search)
            item.searchField.placeholderString = "Search wallpapers"
            item.searchField.target = self
            item.searchField.action = #selector(searchChanged(_:))
            return item
        case .apply:
            let item = NSToolbarItem(itemIdentifier: .apply)
            item.label = "Apply"
            item.image = NSImage(systemSymbolName: "play.circle", accessibilityDescription: nil)
            item.target = self
            item.action = #selector(applySelected)
            return item
        case .launchToggle:
            let item = NSToolbarItem(itemIdentifier: .launchToggle)
            item.label = "Launch at Login"
            let button = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(toggleLaunchAtLogin(_:)))
            button.state = PreferencesStore.load().launchAtLogin ? .on : .off
            item.view = button
            return item
        case .importItem:
            let item = NSToolbarItem(itemIdentifier: .importItem)
            item.label = "Import"
            item.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: nil)
            item.target = self
            item.action = #selector(importLocal)
            return item
        default: return nil
        }
    }

    // MARK: Actions
    @objc private func importLocal() {
        Task { @MainActor in
            // Prefer preview flow so user can confirm before apply
            let importer = LocalWallpaperImporter()
            do {
                if let url = try importer.pickMovie() {
                    self.previewVC.configure(with: url, title: url.deletingPathExtension().lastPathComponent)
                    // User can apply from preview, which calls coordinator.apply(url:)
                }
            } catch {
                NSSound.beep()
            }
        }
    }

    @objc private func openPreferences() { PreferencesWindowController.shared.show() }

    @objc private func applySelected() {
        if let selected = sidebarVC.currentSelection, let url = selected.localFileURL {
            coordinator.apply(url: url)
        }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        var p = PreferencesStore.load(); p.launchAtLogin = (sender.state == .on); PreferencesStore.save(p)
        // TODO: integrate SMAppService to truly toggle login item
    }

    @objc private func searchChanged(_ sender: NSSearchField) {
        sidebarVC.updateSearch(query: sender.stringValue)
    }

    @objc private func handleImportURL(_ note: Notification) {
        guard let url = note.object as? URL else { return }
        self.previewVC.configure(with: url, title: url.deletingPathExtension().lastPathComponent)
    }
}

private extension NSToolbarItem.Identifier {
    static let search = NSToolbarItem.Identifier("ToolbarSearch")
    static let apply = NSToolbarItem.Identifier("ToolbarApply")
    static let launchToggle = NSToolbarItem.Identifier("ToolbarLaunchToggle")
    static let importItem = NSToolbarItem.Identifier("ToolbarImport")
}
