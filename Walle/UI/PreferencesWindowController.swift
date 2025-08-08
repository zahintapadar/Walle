//
//  PreferencesWindowController.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import AppKit
import SwiftUI

final class PreferencesWindowController: NSWindowController {
    static let shared = PreferencesWindowController()

    private override init(window: NSWindow?) {
        let contentVC = NSHostingController(rootView: PreferencesView())
        let prefWindow = NSWindow(contentViewController: contentVC)
        prefWindow.title = "Preferences"
        prefWindow.styleMask = NSWindow.StyleMask([.titled, .closable])
        prefWindow.setContentSize(NSSize(width: 420, height: 220))
        super.init(window: prefWindow)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct PreferencesView: View {
    @State private var prefs = PreferencesStore.load()

    var body: some View {
        Form {
            Toggle("Hide app after apply", isOn: Binding(get: { prefs.hideAppAfterApply }, set: { prefs.hideAppAfterApply = $0; PreferencesStore.save(prefs) }))
            Picker("Default aspect", selection: Binding(get: { prefs.defaultAspect }, set: { prefs.defaultAspect = $0; PreferencesStore.save(prefs) })) {
                Text("Fit").tag(Preferences.AspectMode.fit)
                Text("Fill").tag(Preferences.AspectMode.fill)
                Text("Original").tag(Preferences.AspectMode.original)
            }
            Toggle("Launch at login", isOn: Binding(get: { prefs.launchAtLogin }, set: { prefs.launchAtLogin = $0; PreferencesStore.save(prefs) }))
        }
        .padding()
        .frame(width: 400, height: 160)
    }
}
