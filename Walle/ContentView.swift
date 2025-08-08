//
//  ContentView.swift
//  Walle
//
//  Created by zahin tapadar on 08/08/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor<WallpaperModel>(\.createdAt, order: .reverse)]) private var wallpapers: [WallpaperModel]

    @State private var coordinator: WallpaperCoordinator? = nil
    @State private var downloadURLString: String = ""
    @State private var showSettings = false

    init() {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Button("Import & Preview") { importAndPreview() }
                Spacer()
                TextField("Paste video URL (.mp4/.mov)", text: $downloadURLString)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 320)
                Button("Download & Apply") { startDownload() }
                    .disabled(URL(string: downloadURLString) == nil)
                Button("Settings") { showSettings = true }
            }
            .padding(.horizontal)

            List {
                ForEach(wallpapers) { m in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(m.title).bold()
                            HStack(spacing: 8) {
                                if m.source == .remote { Text("Remote").foregroundStyle(.secondary) } else { Text("Local").foregroundStyle(.secondary) }
                                statusView(for: m)
                            }
                            .font(.caption)
                        }
                        Spacer()
                        Button("Preview") { preview(model: m) }.disabled(m.localFileURL == nil)
                        Button(m.isApplied ? "Applied" : "Apply") {
                            coordinator?.apply(wallpaper: m)
                        }
                        .disabled(!m.isApplied && m.localFileURL == nil)
                    }
                }
            }
        }
        .padding(.vertical)
        .onAppear {
            WindowManager.shared.ensureWindowsForCurrentScreens()
            if coordinator == nil { coordinator = WallpaperCoordinator(modelContext: modelContext) }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private func importAndPreview() {
        let importer = LocalWallpaperImporter()
        do {
            if let url = try importer.pickMovie() {
                showPreview(url: url, title: url.deletingPathExtension().lastPathComponent)
            }
        } catch {
            // user cancelled or error
        }
    }

    private func preview(model: WallpaperModel) {
        guard let url = model.localFileURL else { return }
        showPreview(url: url, title: model.title)
    }

    private func showPreview(url: URL, title: String) {
        let vc = PreviewPanelViewController()
        vc.configure(with: url, title: title)
        vc.onApply = { url, mode in
            switch mode {
            case .fit: WallpaperRenderer.shared.setAspect(.fit)
            case .fill: WallpaperRenderer.shared.setAspect(.fill)
            case .original: WallpaperRenderer.shared.setAspect(.original)
            }
            WallpaperRenderer.shared.playOnAllScreens(url: url)
        }
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 720, height: 320), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        panel.contentViewController = vc
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // Settings sheet content
    private struct SettingsView: View {
        @State private var prefs = PreferencesStore.load()
        @State private var launchEnabled = PreferencesStore.load().launchAtLogin

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Hide app after apply", isOn: Binding(get: { prefs.hideAppAfterApply }, set: { prefs.hideAppAfterApply = $0; PreferencesStore.save(prefs) }))
                Toggle("Launch at login", isOn: Binding(get: { launchEnabled }, set: { launchEnabled = $0; setLaunchAtLogin($0) }))
                Spacer()
            }
            .padding()
            .frame(width: 360, height: 180)
        }

        private func setLaunchAtLogin(_ enabled: Bool) {
            var p = prefs; p.launchAtLogin = enabled; PreferencesStore.save(p)
            // For full functionality, integrate ServiceManagement SMAppService later.
        }
    }

    private func statusView(for m: WallpaperModel) -> some View {
        switch m.downloadStatus {
        case .notDownloaded:
            return Text("Not downloaded")
        case .downloading:
            return Text("Downloading \(Int((m.downloadProgress ?? 0)*100))%")
        case .downloaded:
            return Text("Ready")
        case .failed:
            return Text("Failed").foregroundStyle(.red)
        }
    }

    private func startDownload() {
        guard let url = URL(string: downloadURLString) else { return }
        coordinator?.downloadAndApply(from: url, title: nil)
        downloadURLString = ""
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, WallpaperModel.self], inMemory: true)
}
