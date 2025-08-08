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
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppActivated), name: NSApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDeactivated), name: NSApplication.didResignActiveNotification, object: nil)
        ensureWindowsForCurrentScreens()
        startScreenshotDetection()
    }

    func ensureWindowsForCurrentScreens() {
        if !Thread.isMainThread { return DispatchQueue.main.async { self.ensureWindowsForCurrentScreens() } }
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
                // Keep content view in sync
                if let content = window.contentView { content.frame = window.contentLayoutRect }
                // Reassert level and order to remain behind icons but above desktop picture
                let desktopBase = CGWindowLevelForKey(.desktopWindow)
                window.level = NSWindow.Level(rawValue: Int(desktopBase))
                window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
                window.orderBack(nil)
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
    window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        // Anchor at desktop window level; alternative is desktopIconWindow - 1 depending on setup
        let desktopBase = CGWindowLevelForKey(.desktopWindow)
        window.level = NSWindow.Level(rawValue: Int(desktopBase))
        window.isReleasedWhenClosed = false // persist
        window.hidesOnDeactivate = false
        window.canHide = false // prevent hiding during system operations

        let contentView = NSView(frame: window.contentLayoutRect)
        contentView.wantsLayer = true
        window.contentView = contentView
        window.orderBack(nil)
        return window
    }

    private var screenshotTimer: Timer?
    
    private func startScreenshotDetection() {
        // Monitor for screenshot-related events that might hide our window
        screenshotTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.verifyWindowsVisible()
        }
    }
    
    private func verifyWindowsVisible() {
        for (_, window) in windows {
            if !window.isVisible || window.isMiniaturized {
                DispatchQueue.main.async { [weak self] in
                    window.orderBack(nil)
                    window.makeKeyAndOrderFront(nil)
                    window.orderBack(nil) // back to desktop level
                    self?.reassertWindowLevel(window)
                }
            }
        }
    }
    
    private func reassertWindowLevel(_ window: NSWindow) {
        let desktopBase = CGWindowLevelForKey(.desktopWindow)
        window.level = NSWindow.Level(rawValue: Int(desktopBase))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        WallpaperRenderer.shared.reassert()
    }

    @objc private func handleScreenChange() {
    ensureWindowsForCurrentScreens()
    WallpaperRenderer.shared.resumeAll()
    WallpaperRenderer.shared.setAspect(.fill) // reassert gravity & reattach
    }

    @objc private func handleActiveSpaceChange() {
    ensureWindowsForCurrentScreens()
        WallpaperRenderer.shared.resumeAll()
        WallpaperRenderer.shared.reassert()
    }

    @objc private func handleAppActivated() {
        ensureWindowsForCurrentScreens()
        // Reorder windows to the back at desktop level on app activation
        for window in windows.values { window.orderBack(nil) }
        WallpaperRenderer.shared.reassert()
    }

    @objc private func handleAppDeactivated() {
        // Reassert windows when app loses focus (like during screenshots)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.ensureWindowsForCurrentScreens()
            for window in self.windows.values {
                window.orderBack(nil)
                self.reassertWindowLevel(window)
            }
        }
    }
}
