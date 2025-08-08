//
//  WallpaperStorageManager.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import Foundation
import SwiftData
import AVFoundation
import AppKit

@MainActor
final class WallpaperStorageManager {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // Load all wallpapers sorted by createdAt desc
    func loadAll() -> [WallpaperModel] {
        let descriptor = FetchDescriptor<WallpaperModel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func findExisting(remoteURL: URL) -> WallpaperModel? {
        let d = FetchDescriptor<WallpaperModel>(predicate: #Predicate { $0.remoteURL == remoteURL })
        return (try? context.fetch(d))?.first
    }

    func findExisting(localURL: URL) -> WallpaperModel? {
        let std = localURL.standardizedFileURL
        let d = FetchDescriptor<WallpaperModel>(predicate: #Predicate { $0.localFileURL == std })
        return (try? context.fetch(d))?.first
    }

    func upsert(remoteURL: URL, title: String?) -> WallpaperModel {
        if let existing = findExisting(remoteURL: remoteURL) {
            if let t = title, !t.isEmpty { existing.title = t }
            existing.source = .remote
            existing.updatedAt = .now
            return existing
        }
        let model = WallpaperModel(title: title ?? remoteURL.lastPathComponent, source: .remote, remoteURL: remoteURL, downloadStatus: .downloading)
        context.insert(model)
        try? context.save()
        return model
    }

    func ensureMetadata(for model: WallpaperModel, from localURL: URL) {
        let asset = AVURLAsset(url: localURL)
        // Duration
        let duration = CMTimeGetSeconds(asset.duration)
        if duration.isFinite { model.durationSeconds = duration }
        // Resolution
        if let track = asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            model.resolutionWidth = Double(abs(size.width))
            model.resolutionHeight = Double(abs(size.height))
        }
        // File size
        if let values = try? localURL.resourceValues(forKeys: [.fileSizeKey]), let bytes = values.fileSize {
            model.fileSizeBytes = Int64(bytes)
        }
        // Thumbnail: prefer file URL; also keep inline for fast load
        if model.thumbnailFileURL == nil || (model.thumbnailFileURL != nil && (try? Data(contentsOf: model.thumbnailFileURL!)) == nil) {
            if let data = Self.generateThumbnailPNG(url: localURL) {
                model.thumbnailPNGData = data
                if let url = FileManagerService.saveThumbnail(data, for: model.id) {
                    model.thumbnailFileURL = url
                }
            }
        }
        model.localFileURL = localURL
        model.updatedAt = .now
        try? context.save()
    }

    func ensureThumbnailIfMissing(for model: WallpaperModel) {
        if let file = model.thumbnailFileURL, FileManager.default.fileExists(atPath: file.path) {
            return
        }
        guard let url = model.localFileURL else { return }
        if let data = Self.generateThumbnailPNG(url: url) {
            model.thumbnailPNGData = data
            if let fileURL = FileManagerService.saveThumbnail(data, for: model.id) {
                model.thumbnailFileURL = fileURL
            }
            model.updatedAt = .now
            try? context.save()
        }
    }

    static func generateThumbnailPNG(url: URL) -> Data? {
        let asset = AVURLAsset(url: url)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        let sample = durationSeconds.isFinite && durationSeconds > 1 ? CMTimeMakeWithSeconds(min(1, durationSeconds/2), preferredTimescale: 600) : CMTimeMake(value: 1, timescale: 600)
        do {
            let cg = try gen.copyCGImage(at: sample, actualTime: nil)
            let rep = NSBitmapImageRep(cgImage: cg)
            return rep.representation(using: .png, properties: [:])
        } catch {
            return nil
        }
    }
}
