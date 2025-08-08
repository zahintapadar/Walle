//
//  WalleApp.swift
//  Walle
//
//  Created by zahin tapadar on 08/08/25.
//

import SwiftUI
import SwiftData
import AppKit

@main
struct WalleApp: App {
    private let provider = ModelContainerProvider.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppKitTabsHost()
        }
        .modelContainer(provider.container)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences…") { PreferencesWindowController.shared.show() }.keyboardShortcut(",")
            }
            CommandMenu("Aspect") {
                Button("Fit") { WallpaperRenderer.shared.setAspect(.fit) }
                Button("Fill") { WallpaperRenderer.shared.setAspect(.fill) }
                Button("Original") { WallpaperRenderer.shared.setAspect(.original) }
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Status bar item
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "sparkles.tv", accessibilityDescription: "Walle")
        item.menu = makeMenu()
        self.statusItem = item

        // Auto reapply last wallpaper
        let ctx = ModelContainerProvider.shared.context
        let coordinator = WallpaperCoordinator(modelContext: ctx)
        coordinator.reapplyLastIfAvailable()

        // Bring the SwiftUI-hosted window to front
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
        }
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Walle", action: #selector(openMainWindow), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit Walle", action: #selector(quit), keyEquivalent: "q")
        return menu
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
    }

    @objc private func openPreferences() { PreferencesWindowController.shared.show() }
    @objc private func quit() { NSApp.terminate(nil) }
}

// Hosts the AppKit tab UI in a SwiftUI WindowGroup so we get a single, non-blank window.
private struct AppKitTabsHost: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> NSViewController {
        // Try common runtime names
        let candidates = [
            "WallpaperTabViewController",
            "Walle.WallpaperTabViewController"
        ]
        for name in candidates {
            if let cls = NSClassFromString(name) as? NSViewController.Type {
                return cls.init()
            }
        }
        // Visible fallback so the window isn't blank, with a hint for target membership
        let vc = NSViewController()
        let label = NSTextField(labelWithString: "UI failed to load. Ensure UI/*.swift are in the Walle target.")
        label.alignment = .center
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
        ])
        return vc
    }
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}


