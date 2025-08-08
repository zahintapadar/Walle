//
//  WindowManager.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import AppKit

final class WindowManager: NSObject {
    static let shared = WindowManager()

    private var windows: [ObjectIdentifier: NSWindow] = [:]

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenChange), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleActiveSpaceChange), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        ensureWindowsForCurrentScreens()
    }

    func ensureWindowsForCurrentScreens() {
        // Remove windows for detached screens
        for (key, window) in windows {
            let stillExists = NSScreen.screens.contains { ObjectIdentifier($0) == key }
            if !stillExists {
                window.orderOut(nil)
                windows.removeValue(forKey: key)
            }
        }
        // Ensure one window per screen
        for screen in NSScreen.screens {
            let key = ObjectIdentifier(screen)
            if windows[key] == nil {
                windows[key] = createDesktopWindow(for: screen)
            }
            // Resize and place window
            if let window = windows[key] {
                window.setFrame(screen.frame, display: true)
            }
        }
    }

    func window(for screen: NSScreen) -> NSWindow? {
        return windows[ObjectIdentifier(screen)]
    }

    func window(forKey key: ObjectIdentifier) -> NSWindow? {
        return windows[key]
    }

    private func createDesktopWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false, screen: screen)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        // Place the window just below desktop icons (above desktop picture)
        let level = CGWindowLevelForKey(.desktopIconWindow) - 1
        window.level = NSWindow.Level(rawValue: Int(level))
        window.isReleasedWhenClosed = false // persist
        window.hidesOnDeactivate = false

        let contentView = NSView(frame: window.contentLayoutRect)
        contentView.wantsLayer = true
        window.contentView = contentView
        window.orderBack(nil)
        return window
    }

    @objc private func handleScreenChange() {
        ensureWindowsForCurrentScreens()
    }

    @objc private func handleActiveSpaceChange() {
        ensureWindowsForCurrentScreens()
    }
}
