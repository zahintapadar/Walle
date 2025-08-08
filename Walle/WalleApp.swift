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
            AppKitMainWindow()
        }
        .modelContainer(provider.container)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences…") { PreferencesWindowController.shared.show() }.keyboardShortcut(",")
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
        let ctx = ModelContainerProvider.shared.context
        let controller = MainWindowController(modelContext: ctx)
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openPreferences() { PreferencesWindowController.shared.show() }
    @objc private func quit() { NSApp.terminate(nil) }
}

private struct AppKitMainWindow: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = BridgedMainController()
        return controller
    }
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

private final class BridgedMainController: NSViewController {
    private var windowController: MainWindowController?

    override func viewDidAppear() {
        super.viewDidAppear()
        if windowController == nil {
            let ctx = ModelContainerProvider.shared.context
            windowController = MainWindowController(modelContext: ctx)
            windowController?.showWindow(nil)
        }
    }
}
