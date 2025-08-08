//
//  WallpaperCoordinator.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import AppKit
import SwiftData
import AVFoundation

@MainActor
final class WallpaperCoordinator {
    private let modelContext: ModelContext
    private let downloader = VideoDownloader()
    private let importer = LocalWallpaperImporter()
    private lazy var storage = WallpaperStorageManager(context: modelContext)

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _ = WindowManager.shared // initialize windows early
    }

    // MARK: Public API

    func importAndApply() {
        do {
            guard let picked = try importer.pickMovie() else { return }
            let didAccess = picked.startAccessingSecurityScopedResource()
            defer { if didAccess { picked.stopAccessingSecurityScopedResource() } }

            guard FileManager.default.fileExists(atPath: picked.path) else { return }
            let title = picked.deletingPathExtension().lastPathComponent
            let dest: URL = (try? FileManagerService.moveToLibrary(from: picked, preferredTitle: title)) ?? picked

            let asset = AVURLAsset(url: dest)
            guard asset.isPlayable else { return }

            // Upsert by local URL (avoid duplicates)
            if let model = storage.findExisting(localURL: dest) {
                model.downloadStatus = .downloaded
                model.isApplied = true
                model.updatedAt = .now
                storage.ensureMetadata(for: model, from: dest)
            } else {
                let model = WallpaperModel(title: dest.deletingPathExtension().lastPathComponent,
                                           source: .local,
                                           localFileURL: dest,
                                           downloadStatus: .downloaded,
                                           isApplied: true)
                modelContext.insert(model)
                storage.ensureMetadata(for: model, from: dest)
            }
            // Clear others applied
            if let all = try? modelContext.fetch(FetchDescriptor<WallpaperModel>()) {
                if let current = all.first(where: { $0.localFileURL?.standardizedFileURL == dest.standardizedFileURL }) {
                    for m in all { m.isApplied = (m.id == current.id) }
                }
            }
            try? modelContext.save()

            apply(url: dest)
        } catch { return }
    }

    func downloadAndApply(from url: URL, title: String? = nil) {
        // Upsert and mark downloading
        let model = storage.upsert(remoteURL: url, title: title)
        model.downloadStatus = .downloading
        try? modelContext.save()

        downloader.download(from: url, progress: { [weak self] p in
            guard let self else { return }
            model.downloadStatus = .downloading
            model.downloadProgress = p
            model.updatedAt = .now
            try? self.modelContext.save()
        }, completion: { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let localURL):
                    model.localFileURL = localURL
                    model.downloadStatus = .downloaded
                    model.downloadProgress = 1.0
                    model.isApplied = true
                    self.storage.ensureMetadata(for: model, from: localURL)
                    // clear others applied
                    if let all = try? self.modelContext.fetch(FetchDescriptor<WallpaperModel>()) {
                        for m in all { m.isApplied = (m.id == model.id) }
                    }
                    try? self.modelContext.save()
                    self.apply(url: localURL)
                case .failure(let err):
                    model.downloadStatus = .failed
                    model.lastErrorMessage = err.localizedDescription
                    model.updatedAt = .now
                    try? self.modelContext.save()
                }
            }
        })
    }

    func apply(wallpaper model: WallpaperModel) {
        guard let url = model.localFileURL else { return }
        apply(url: url)
        // Mark applied
        if let all = try? modelContext.fetch(FetchDescriptor<WallpaperModel>()) {
            for m in all { m.isApplied = (m.id == model.id) }
        }
        model.updatedAt = .now
        try? modelContext.save()
    }

    func list() throws -> [WallpaperModel] {
        let descriptor = FetchDescriptor<WallpaperModel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    // MARK: Public
    func apply(url: URL) {
        // Render immediately
        WallpaperRenderer.shared.playOnAllScreens(url: url)

        // Persist selection for auto-reapply and metadata enrichment
        do {
            let all = try modelContext.fetch(FetchDescriptor<WallpaperModel>())
            let stdURL = url.standardizedFileURL
            let storage = self.storage
            if let existing = all.first(where: { $0.localFileURL?.standardizedFileURL == stdURL }) {
                for m in all { m.isApplied = (m.id == existing.id) }
                existing.updatedAt = .now
                storage.ensureMetadata(for: existing, from: stdURL)
                try? modelContext.save()
            } else {
                let dest = (try? FileManagerService.moveToLibrary(from: stdURL, preferredTitle: stdURL.deletingPathExtension().lastPathComponent)) ?? stdURL
                let model = WallpaperModel(title: dest.deletingPathExtension().lastPathComponent,
                                           source: .local,
                                           remoteURL: nil,
                                           localFileURL: dest,
                                           downloadStatus: .downloaded,
                                           isApplied: true,
                                           createdAt: .now,
                                           updatedAt: .now)
                for m in all { m.isApplied = false }
                modelContext.insert(model)
                storage.ensureMetadata(for: model, from: dest)
                try? modelContext.save()
            }
        } catch { }

        if PreferencesStore.load().hideAppAfterApply { NSApp.mainWindow?.miniaturize(nil) }
    }

    func reapplyLastIfAvailable() {
        let appliedDescriptor = FetchDescriptor<WallpaperModel>(predicate: #Predicate { $0.isApplied == true }, sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        let downloadedDescriptor = FetchDescriptor<WallpaperModel>(predicate: #Predicate { $0.downloadStatusRaw == "downloaded" }, sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        let applied = (try? modelContext.fetch(appliedDescriptor)) ?? []
        let model = applied.first ?? ((try? modelContext.fetch(downloadedDescriptor))?.first)
        guard let m = model, let url = m.localFileURL else { return }

        // Ensure thumbnail exists
        storage.ensureThumbnailIfMissing(for: m)

        let prefs = PreferencesStore.load()
        switch prefs.defaultAspect {
        case .fit: WallpaperRenderer.shared.setAspect(.fit)
        case .fill: WallpaperRenderer.shared.setAspect(.fill)
        case .original: WallpaperRenderer.shared.setAspect(.original)
        }
        apply(url: url)
    }
}
